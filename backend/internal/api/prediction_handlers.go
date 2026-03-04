package api

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"soundsync/backend/internal/predictions"
)

func (h *Handler) predictDelay(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	in, err := parsePredictionInput(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if strings.TrimSpace(in.RouteID) == "" {
		writeError(w, http.StatusBadRequest, "routeId is required")
		return
	}

	result, err := h.predictionSvc.PredictDelay(in)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to compute delay prediction")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"prediction": result})
}

func (h *Handler) predictCrowding(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	in, err := parsePredictionInput(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if strings.TrimSpace(in.RouteID) == "" {
		writeError(w, http.StatusBadRequest, "routeId is required")
		return
	}

	result, err := h.predictionSvc.PredictCrowding(in)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to compute crowding prediction")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"prediction": result})
}

// parsePredictionInput reads routeId, stopId, directionId, and at (RFC3339)
// from query parameters.
func parsePredictionInput(r *http.Request) (predictions.PredictionInput, error) {
	q := r.URL.Query()
	in := predictions.PredictionInput{
		RouteID: q.Get("routeId"),
		StopID:  q.Get("stopId"),
	}

	if d := strings.TrimSpace(q.Get("directionId")); d != "" {
		v, err := strconv.Atoi(d)
		if err != nil {
			return predictions.PredictionInput{}, errors.New("directionId must be an integer")
		}
		in.DirectionID = &v
	}

	if atStr := strings.TrimSpace(q.Get("at")); atStr != "" {
		t, err := time.Parse(time.RFC3339, atStr)
		if err != nil {
			return predictions.PredictionInput{}, errors.New("at must be RFC3339 (e.g. 2026-03-04T08:00:00Z)")
		}
		in.At = t.UTC()
	}

	return in, nil
}
