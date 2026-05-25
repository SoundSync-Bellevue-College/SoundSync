package handlers

import (
	"net/http"

	"soundsync/api/internal/repository"
)

type TeamHandler struct {
	repo *repository.TeamRepo
}

func NewTeamHandler(repo *repository.TeamRepo) *TeamHandler {
	return &TeamHandler{repo: repo}
}

// GET /api/v1/team
func (h *TeamHandler) GetTeam(w http.ResponseWriter, r *http.Request) {
	members, err := h.repo.GetAll(r.Context())
	if err != nil {
		jsonOK(w, map[string]interface{}{"success": false, "error": "failed to load team"}, http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{
		"success": true,
		"data":    members,
	}, http.StatusOK)
}
