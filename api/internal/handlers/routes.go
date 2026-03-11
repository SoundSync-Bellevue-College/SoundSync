package handlers

import (
	"net/http"

	"soundsync/api/internal/repository"
	"soundsync/api/internal/services"

	"github.com/go-chi/chi/v5"
)

type RouteHandler struct {
	routeSvc *services.RouteService
	favRepo  *repository.FavoriteRepo
}

func NewRouteHandler(routeSvc *services.RouteService, favRepo *repository.FavoriteRepo) *RouteHandler {
	return &RouteHandler{routeSvc: routeSvc, favRepo: favRepo}
}

func (h *RouteHandler) PlanRoute(w http.ResponseWriter, r *http.Request) {
	origin := r.URL.Query().Get("origin")
	dest := r.URL.Query().Get("dest")
	if origin == "" || dest == "" {
		jsonError(w, "origin and dest are required", http.StatusBadRequest)
		return
	}

	// Optional: Unix timestamp strings forwarded from the client
	departureTime := r.URL.Query().Get("departure_time")
	arrivalTime := r.URL.Query().Get("arrival_time")

	result, err := h.routeSvc.PlanRoute(r.Context(), origin, dest, departureTime, arrivalTime)
	if err != nil {
		jsonError(w, "route planning failed", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

func (h *RouteHandler) GetRoute(w http.ResponseWriter, r *http.Request) {
	routeID := chi.URLParam(r, "routeId")
	route, err := h.routeSvc.GetRoute(r.Context(), routeID)
	if err != nil {
		jsonError(w, "route not found", http.StatusNotFound)
		return
	}
	jsonOK(w, route, http.StatusOK)
}
