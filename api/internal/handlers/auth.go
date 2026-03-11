package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"soundsync/api/internal/services"
)

type AuthHandler struct {
	authSvc *services.AuthService
}

func NewAuthHandler(authSvc *services.AuthService) *AuthHandler {
	return &AuthHandler{authSvc: authSvc}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email       string `json:"email"`
		Password    string `json:"password"`
		DisplayName string `json:"displayName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	body.Email = strings.TrimSpace(strings.ToLower(body.Email))
	if body.Email == "" || body.Password == "" || body.DisplayName == "" {
		jsonError(w, "email, password, and displayName are required", http.StatusBadRequest)
		return
	}
	if len(body.Password) < 8 {
		jsonError(w, "password must be at least 8 characters", http.StatusBadRequest)
		return
	}

	user, token, err := h.authSvc.Register(r.Context(), body.Email, body.Password, body.DisplayName)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "E11000") {
			jsonError(w, "email already registered", http.StatusConflict)
			return
		}
		jsonError(w, "registration failed", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{"token": token, "user": user}, http.StatusCreated)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	user, token, err := h.authSvc.Login(r.Context(), body.Email, body.Password)
	if err != nil {
		jsonError(w, err.Error(), http.StatusUnauthorized)
		return
	}

	jsonOK(w, map[string]interface{}{"token": token, "user": user}, http.StatusOK)
}
