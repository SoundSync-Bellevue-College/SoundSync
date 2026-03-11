package handlers

import (
	"net/http"
	"strconv"

	"soundsync/api/internal/services"
)

type TransitHandler struct {
	transitSvc *services.TransitService
}

func NewTransitHandler(transitSvc *services.TransitService) *TransitHandler {
	return &TransitHandler{transitSvc: transitSvc}
}

func (h *TransitHandler) GetVehicles(w http.ResponseWriter, r *http.Request) {
	vehicles, err := h.transitSvc.GetVehicles(r.Context())
	if err != nil {
		jsonError(w, "failed to fetch vehicles", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{"vehicles": vehicles}, http.StatusOK)
}

func (h *TransitHandler) GetNearbyStops(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	lat, _ := strconv.ParseFloat(q.Get("lat"), 64)
	lng, _ := strconv.ParseFloat(q.Get("lng"), 64)
	radius, _ := strconv.Atoi(q.Get("radius"))
	if radius == 0 {
		radius = 500
	}

	stops, err := h.transitSvc.GetNearbyStops(r.Context(), lat, lng, radius)
	if err != nil {
		jsonError(w, "failed to fetch stops", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{"stops": stops}, http.StatusOK)
}

func (h *TransitHandler) GetArrivals(w http.ResponseWriter, r *http.Request) {
	stopID := r.URL.Query().Get("stopId")
	if stopID == "" {
		jsonError(w, "stopId is required", http.StatusBadRequest)
		return
	}

	arrivals, err := h.transitSvc.GetArrivals(r.Context(), stopID)
	if err != nil {
		jsonError(w, "failed to fetch arrivals", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{"arrivals": arrivals}, http.StatusOK)
}
