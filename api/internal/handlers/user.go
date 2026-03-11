package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"soundsync/api/internal/middleware"
	"soundsync/api/internal/models"
	"soundsync/api/internal/repository"

	"github.com/go-chi/chi/v5"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type UserHandler struct {
	userRepo   *repository.UserRepo
	favRepo    *repository.FavoriteRepo
	reportRepo *repository.ReportRepo
	notifRepo  *repository.NotificationRepo
}

func NewUserHandler(
	userRepo *repository.UserRepo,
	favRepo *repository.FavoriteRepo,
	reportRepo *repository.ReportRepo,
	notifRepo *repository.NotificationRepo,
) *UserHandler {
	return &UserHandler{
		userRepo:   userRepo,
		favRepo:    favRepo,
		reportRepo: reportRepo,
		notifRepo:  notifRepo,
	}
}

func (h *UserHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	user, err := h.userRepo.FindByID(r.Context(), userID)
	if err != nil {
		jsonError(w, "user not found", http.StatusNotFound)
		return
	}
	jsonOK(w, user, http.StatusOK)
}

// DeleteMe soft-deletes the authenticated user (sets deleted: true).
func (h *UserHandler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	if err := h.userRepo.SoftDelete(r.Context(), userID); err != nil {
		jsonError(w, "failed to delete account", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *UserHandler) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))

	var body struct {
		NotificationsEnabled *bool   `json:"notificationsEnabled"`
		TempUnit             *string `json:"tempUnit"`
		DistanceUnit         *string `json:"distanceUnit"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	updates := bson.M{}
	if body.NotificationsEnabled != nil {
		updates["notificationsEnabled"] = *body.NotificationsEnabled
	}
	if body.TempUnit != nil {
		if *body.TempUnit != "F" && *body.TempUnit != "C" {
			jsonError(w, "tempUnit must be F or C", http.StatusBadRequest)
			return
		}
		updates["tempUnit"] = *body.TempUnit
	}
	if body.DistanceUnit != nil {
		if *body.DistanceUnit != "mi" && *body.DistanceUnit != "km" {
			jsonError(w, "distanceUnit must be mi or km", http.StatusBadRequest)
			return
		}
		updates["distanceUnit"] = *body.DistanceUnit
	}
	if len(updates) == 0 {
		jsonError(w, "no settings provided", http.StatusBadRequest)
		return
	}

	if err := h.userRepo.Update(r.Context(), userID, updates); err != nil {
		jsonError(w, "failed to update settings", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Favorites ───────────────────────────────────────────────────────────────

func (h *UserHandler) GetFavorites(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	favs, err := h.favRepo.FindByUserID(r.Context(), userID)
	if err != nil {
		jsonError(w, "failed to load favorites", http.StatusInternalServerError)
		return
	}
	if favs == nil {
		favs = []models.FavoriteRoute{}
	}
	jsonOK(w, map[string]interface{}{"favorites": favs}, http.StatusOK)
}

func (h *UserHandler) CreateFavorite(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))

	var body struct {
		Label           string          `json:"label"`
		Origin          models.PlaceRef `json:"origin"`
		Destination     models.PlaceRef `json:"destination"`
		TransitRouteIDs []string        `json:"transitRouteIds"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	fav := &models.FavoriteRoute{
		UserID:          userID,
		Label:           body.Label,
		Origin:          body.Origin,
		Destination:     body.Destination,
		TransitRouteIDs: body.TransitRouteIDs,
	}

	if err := h.favRepo.Create(r.Context(), fav); err != nil {
		jsonError(w, "failed to create favorite", http.StatusInternalServerError)
		return
	}
	jsonOK(w, fav, http.StatusCreated)
}

func (h *UserHandler) DeleteFavorite(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	idStr := chi.URLParam(r, "id")

	id, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	if err := h.favRepo.Delete(r.Context(), id, userID); err != nil {
		jsonError(w, "failed to delete favorite", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Reports ─────────────────────────────────────────────────────────────────

func (h *UserHandler) CreateReport(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))

	var body struct {
		RouteID     string         `json:"routeId"`
		VehicleID   string         `json:"vehicleId"`
		Type        string         `json:"type"`
		Severity    string         `json:"severity"`
		Description string         `json:"description"`
		Location    *models.LatLng `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	report := &models.Report{
		UserID:      userID,
		RouteID:     body.RouteID,
		VehicleID:   body.VehicleID,
		Type:        body.Type,
		Severity:    body.Severity,
		Description: body.Description,
		Location:    body.Location,
	}

	if err := h.reportRepo.Create(r.Context(), report); err != nil {
		jsonError(w, "failed to create report", http.StatusInternalServerError)
		return
	}

	// Fire-and-forget: fan out notifications to users who favorited this route.
	go h.fanOutNotifications(body.RouteID, body.Type, userID)

	jsonOK(w, report, http.StatusCreated)
}

func (h *UserHandler) fanOutNotifications(routeID, reportType string, reporterID primitive.ObjectID) {
	ctx := context.Background()

	favs, err := h.favRepo.FindByRouteID(ctx, routeID)
	if err != nil {
		return
	}

	seen := map[primitive.ObjectID]bool{}
	for _, fav := range favs {
		if fav.UserID == reporterID || seen[fav.UserID] {
			continue
		}
		seen[fav.UserID] = true

		owner, err := h.userRepo.FindByID(ctx, fav.UserID)
		if err != nil || !owner.NotificationsEnabled {
			continue
		}

		n := &models.Notification{
			UserID:     fav.UserID,
			RouteID:    routeID,
			ReportType: reportType,
			Message:    fmt.Sprintf("New %s report on route %s", reportType, routeID),
			Read:       false,
		}
		_ = h.notifRepo.Create(ctx, n)
	}
}

func (h *UserHandler) GetReports(w http.ResponseWriter, r *http.Request) {
	routeID := r.URL.Query().Get("routeId")
	if routeID == "" {
		jsonError(w, "routeId is required", http.StatusBadRequest)
		return
	}

	reports, err := h.reportRepo.FindByRouteID(r.Context(), routeID)
	if err != nil {
		jsonError(w, "failed to load reports", http.StatusInternalServerError)
		return
	}
	if reports == nil {
		reports = []models.Report{}
	}
	jsonOK(w, map[string]interface{}{"reports": reports}, http.StatusOK)
}

func mustObjectID(hex string) primitive.ObjectID {
	id, _ := primitive.ObjectIDFromHex(hex)
	return id
}
