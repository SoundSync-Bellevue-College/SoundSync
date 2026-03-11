package handlers

import (
	"encoding/json"
	"net/http"

	"soundsync/api/internal/middleware"
	"soundsync/api/internal/models"
	"soundsync/api/internal/repository"

	"github.com/go-chi/chi/v5"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GET /users/me/vehicle-reports — returns all reports submitted by the caller.
func (h *VehicleReportHandler) GetMyReports(w http.ResponseWriter, r *http.Request) {
	userIDStr := middleware.GetUserID(r)
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	reports, err := h.repo.FindByUserID(r.Context(), userID)
	if err != nil {
		jsonError(w, "failed to load reports", http.StatusInternalServerError)
		return
	}
	if reports == nil {
		reports = []models.VehicleReportSummary{}
	}
	jsonOK(w, map[string]interface{}{"reports": reports}, http.StatusOK)
}

// DELETE /users/me/vehicle-reports/:type/:id — deletes a specific report owned by the caller.
func (h *VehicleReportHandler) DeleteMyReport(w http.ResponseWriter, r *http.Request) {
	userIDStr := middleware.GetUserID(r)
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	reportType := chi.URLParam(r, "type")
	idStr := chi.URLParam(r, "id")
	id, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		jsonError(w, "invalid report id", http.StatusBadRequest)
		return
	}
	if err := h.repo.DeleteByIDAndUser(r.Context(), reportType, id, userID); err != nil {
		jsonError(w, err.Error(), http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type VehicleReportHandler struct {
	repo *repository.VehicleReportRepo
}

func NewVehicleReportHandler(repo *repository.VehicleReportRepo) *VehicleReportHandler {
	return &VehicleReportHandler{repo: repo}
}

type vehicleReportBody struct {
	RouteID string `json:"routeId"`
	Level   int    `json:"level"`
}

func (h *VehicleReportHandler) parseCommon(w http.ResponseWriter, r *http.Request) (vehicleID string, userID primitive.ObjectID, body vehicleReportBody, ok bool) {
	vehicleID = chi.URLParam(r, "vehicleId")
	if vehicleID == "" {
		jsonError(w, "vehicleId is required", http.StatusBadRequest)
		return
	}

	userIDStr := middleware.GetUserID(r)
	uid, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	userID = uid

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if body.Level < 1 || body.Level > 5 {
		jsonError(w, "level must be between 1 and 5", http.StatusBadRequest)
		return
	}

	ok = true
	return
}

// POST /transit/vehicles/:vehicleId/report/cleanliness
func (h *VehicleReportHandler) CreateCleanliness(w http.ResponseWriter, r *http.Request) {
	vehicleID, userID, body, ok := h.parseCommon(w, r)
	if !ok {
		return
	}

	report := &models.CleanlinessReport{
		UserID:    userID,
		VehicleID: vehicleID,
		RouteID:   body.RouteID,
		Level:     body.Level,
	}
	if err := h.repo.CreateCleanliness(r.Context(), report); err != nil {
		jsonError(w, "failed to save cleanliness report", http.StatusInternalServerError)
		return
	}
	jsonOK(w, report, http.StatusCreated)
}

// POST /transit/vehicles/:vehicleId/report/crowding
func (h *VehicleReportHandler) CreateCrowding(w http.ResponseWriter, r *http.Request) {
	vehicleID, userID, body, ok := h.parseCommon(w, r)
	if !ok {
		return
	}

	report := &models.CrowdingReport{
		UserID:    userID,
		VehicleID: vehicleID,
		RouteID:   body.RouteID,
		Level:     body.Level,
	}
	if err := h.repo.CreateCrowding(r.Context(), report); err != nil {
		jsonError(w, "failed to save crowding report", http.StatusInternalServerError)
		return
	}
	jsonOK(w, report, http.StatusCreated)
}

// POST /transit/vehicles/:vehicleId/report/delay
func (h *VehicleReportHandler) CreateDelay(w http.ResponseWriter, r *http.Request) {
	vehicleID, userID, body, ok := h.parseCommon(w, r)
	if !ok {
		return
	}

	report := &models.DelayReport{
		UserID:    userID,
		VehicleID: vehicleID,
		RouteID:   body.RouteID,
		Level:     body.Level,
	}
	if err := h.repo.CreateDelay(r.Context(), report); err != nil {
		jsonError(w, "failed to save delay report", http.StatusInternalServerError)
		return
	}
	jsonOK(w, report, http.StatusCreated)
}
