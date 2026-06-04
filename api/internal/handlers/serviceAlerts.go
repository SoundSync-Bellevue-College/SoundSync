package handlers

import (
	"net/http"

	"soundsync/api/internal/services"
)

type ServiceAlertsHandler struct {
	svc *services.ServiceAlertsService
}

func NewServiceAlertsHandler(svc *services.ServiceAlertsService) *ServiceAlertsHandler {
	return &ServiceAlertsHandler{svc: svc}
}

func (h *ServiceAlertsHandler) GetAlerts(w http.ResponseWriter, r *http.Request) {
	agency := r.URL.Query().Get("agency")

	alerts, err := h.svc.GetAlerts(r.Context(), agency)
	if err != nil {
		jsonError(w, "failed to fetch service alerts", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{"alerts": alerts}, http.StatusOK)
}
