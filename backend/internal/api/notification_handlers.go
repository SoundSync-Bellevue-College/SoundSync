package api

import (
	"encoding/json"
	"net/http"
	"strings"
)

func (h *Handler) getNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	prefs, err := h.notif.GetPreferences(userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load preferences")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": prefs})
}

type updatePreferencesRequest struct {
	Enabled bool `json:"enabled"`
}

func (h *Handler) updateNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req updatePreferencesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON payload")
		return
	}

	prefs, err := h.notif.SetEnabled(userID, req.Enabled)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update preferences")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": prefs})
}

type subscribeRequest struct {
	RouteID string `json:"routeId"`
}

func (h *Handler) addSubscription(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req subscribeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON payload")
		return
	}

	prefs, err := h.notif.Subscribe(userID, req.RouteID)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": prefs})
}

func (h *Handler) removeSubscription(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	routeID := strings.TrimPrefix(r.URL.Path, "/api/v1/notifications/subscriptions/")
	routeID = strings.Trim(routeID, "/")
	if routeID == "" {
		writeError(w, http.StatusBadRequest, "routeId is required")
		return
	}

	prefs, err := h.notif.Unsubscribe(userID, routeID)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": prefs})
}
