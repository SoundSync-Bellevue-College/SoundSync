package handlers

import (
	"net/http"
	"strconv"

	"soundsync/api/internal/services"
)

type WeatherHandler struct {
	weatherSvc *services.WeatherService
}

func NewWeatherHandler(weatherSvc *services.WeatherService) *WeatherHandler {
	return &WeatherHandler{weatherSvc: weatherSvc}
}

func (h *WeatherHandler) GetWeather(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	lat, _ := strconv.ParseFloat(q.Get("lat"), 64)
	lng, _ := strconv.ParseFloat(q.Get("lng"), 64)

	result, err := h.weatherSvc.GetWeather(r.Context(), lat, lng)
	if err != nil {
		jsonError(w, "failed to fetch weather", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

func (h *WeatherHandler) GetHourlyForecast(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	lat, _ := strconv.ParseFloat(q.Get("lat"), 64)
	lng, _ := strconv.ParseFloat(q.Get("lng"), 64)

	result, err := h.weatherSvc.GetHourlyForecast(r.Context(), lat, lng)
	if err != nil {
		jsonError(w, "failed to fetch hourly forecast", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}
