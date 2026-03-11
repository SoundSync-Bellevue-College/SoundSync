package handlers

import (
	"net/http"

	"soundsync/api/internal/middleware"
	"soundsync/api/internal/models"
	"soundsync/api/internal/repository"

	"github.com/go-chi/chi/v5"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type NotificationHandler struct {
	notifRepo *repository.NotificationRepo
}

func NewNotificationHandler(notifRepo *repository.NotificationRepo) *NotificationHandler {
	return &NotificationHandler{notifRepo: notifRepo}
}

func (h *NotificationHandler) GetNotifications(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	notifications, err := h.notifRepo.FindByUserID(r.Context(), userID)
	if err != nil {
		jsonError(w, "failed to load notifications", http.StatusInternalServerError)
		return
	}
	if notifications == nil {
		notifications = []models.Notification{}
	}
	jsonOK(w, map[string]interface{}{"notifications": notifications}, http.StatusOK)
}

func (h *NotificationHandler) MarkRead(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	idStr := chi.URLParam(r, "id")

	id, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	if err := h.notifRepo.MarkRead(r.Context(), id, userID); err != nil {
		jsonError(w, "failed to mark notification read", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *NotificationHandler) MarkAllRead(w http.ResponseWriter, r *http.Request) {
	userID := mustObjectID(middleware.GetUserID(r))
	if err := h.notifRepo.MarkAllRead(r.Context(), userID); err != nil {
		jsonError(w, "failed to mark all notifications read", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
