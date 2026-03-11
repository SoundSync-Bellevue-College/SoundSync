package services

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"time"

	"soundsync/api/internal/config"
)

type RouteService struct {
	cfg    *config.Config
	client *http.Client
}

func NewRouteService(cfg *config.Config) *RouteService {
	return &RouteService{
		cfg:    cfg,
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

// PlanRoute proxies Google Maps Directions API for transit routing.
// departureTime and arrivalTime are optional Unix timestamp strings (only one should be set).
func (s *RouteService) PlanRoute(ctx context.Context, origin, dest, departureTime, arrivalTime string) (map[string]interface{}, error) {
	if s.cfg.GoogleMapsKey == "" {
		return map[string]interface{}{"error": "Google Maps API key not configured"}, nil
	}

	params := url.Values{}
	params.Set("origin", origin)
	params.Set("destination", dest)
	params.Set("mode", "transit")
	params.Set("key", s.cfg.GoogleMapsKey)
	if departureTime != "" {
		params.Set("departure_time", departureTime)
	} else if arrivalTime != "" {
		params.Set("arrival_time", arrivalTime)
	}

	reqURL := "https://maps.googleapis.com/maps/api/directions/json?" + params.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

// GetRoute returns static GTFS route data by ID.
// TODO: parse GTFS static routes.txt
func (s *RouteService) GetRoute(_ context.Context, routeID string) (map[string]interface{}, error) {
	return map[string]interface{}{
		"routeId":   routeID,
		"shortName": routeID,
		"longName":  "Route " + routeID,
		"type":      3,
	}, nil
}
