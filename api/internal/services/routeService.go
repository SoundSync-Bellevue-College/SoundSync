package services

import (
	"context"
	"encoding/json"
	"fmt"
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
func (s *RouteService) GetRoute(_ context.Context, routeID string) (map[string]interface{}, error) {
	return map[string]interface{}{
		"routeId":   routeID,
		"shortName": routeID,
		"longName":  "Route " + routeID,
		"type":      3,
	}, nil
}

// RouteStop is a stop returned as part of a route shape response.
type RouteStop struct {
	ID   string  `json:"id"`
	Name string  `json:"name"`
	Code string  `json:"code"`
	Lat  float64 `json:"lat"`
	Lng  float64 `json:"lng"`
}

// RouteShapeResult holds encoded polylines and the ordered list of stops for a route.
type RouteShapeResult struct {
	Polylines []string    `json:"polylines"`
	Stops     []RouteStop `json:"stops"`
}

// GetRouteShape fetches the route path and stops from OBA.
// Strategy:
//  1. stops-for-route → stops + try embedded polylines
//  2. If polylines are empty, trips-for-route → shape/{shapeId} (more reliable)
func (s *RouteService) GetRouteShape(ctx context.Context, routeID string) (*RouteShapeResult, error) {
	// ── Step 1: stops-for-route ──────────────────────────────────────────────
	stopsURL := fmt.Sprintf(
		"%s/api/where/stops-for-route/%s.json?key=%s&includePolylines=true",
		s.cfg.OBABaseURL, routeID, s.cfg.OBAApiKey,
	)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, stopsURL, nil)
	if err != nil {
		return nil, err
	}
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var stopsResp struct {
		Data struct {
			Entry struct {
				StopIds   []string `json:"stopIds"`
				Polylines []struct {
					Points string `json:"points"`
				} `json:"polylines"`
			} `json:"entry"`
			References struct {
				Stops []struct {
					ID   string  `json:"id"`
					Name string  `json:"name"`
					Code string  `json:"code"`
					Lat  float64 `json:"lat"`
					Lon  float64 `json:"lon"`
				} `json:"stops"`
			} `json:"references"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&stopsResp); err != nil {
		return nil, err
	}

	// Build stop lookup from references
	stopLookup := make(map[string]RouteStop, len(stopsResp.Data.References.Stops))
	for _, s := range stopsResp.Data.References.Stops {
		stopLookup[s.ID] = RouteStop{ID: s.ID, Name: s.Name, Code: s.Code, Lat: s.Lat, Lng: s.Lon}
	}

	// Collect stops in route stop ID order
	stops := make([]RouteStop, 0, len(stopsResp.Data.Entry.StopIds))
	for _, id := range stopsResp.Data.Entry.StopIds {
		if s, ok := stopLookup[id]; ok {
			stops = append(stops, s)
		}
	}

	// Collect any embedded polylines
	polylines := make([]string, 0, len(stopsResp.Data.Entry.Polylines))
	for _, p := range stopsResp.Data.Entry.Polylines {
		if p.Points != "" {
			polylines = append(polylines, p.Points)
		}
	}

	// ── Step 2: if no polylines, get shape via trips-for-route ───────────────
	if len(polylines) == 0 {
		if encoded := s.fetchShapeViaTrips(ctx, routeID); encoded != "" {
			polylines = []string{encoded}
		}
	}

	return &RouteShapeResult{Polylines: polylines, Stops: stops}, nil
}

// fetchShapeViaTrips calls trips-for-route to get a shapeId, then fetches
// that shape's encoded polyline. Returns "" on any failure.
func (s *RouteService) fetchShapeViaTrips(ctx context.Context, routeID string) string {
	tripsURL := fmt.Sprintf(
		"%s/api/where/trips-for-route/%s.json?key=%s&includeTrips=true",
		s.cfg.OBABaseURL, routeID, s.cfg.OBAApiKey,
	)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, tripsURL, nil)
	if err != nil {
		return ""
	}
	resp, err := s.client.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	var tripsResp struct {
		Data struct {
			List []struct {
				ShapeID string `json:"shapeId"`
			} `json:"list"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tripsResp); err != nil || len(tripsResp.Data.List) == 0 {
		return ""
	}

	shapeID := tripsResp.Data.List[0].ShapeID
	if shapeID == "" {
		return ""
	}

	shapeURL := fmt.Sprintf(
		"%s/api/where/shape/%s.json?key=%s",
		s.cfg.OBABaseURL, shapeID, s.cfg.OBAApiKey,
	)
	req2, err := http.NewRequestWithContext(ctx, http.MethodGet, shapeURL, nil)
	if err != nil {
		return ""
	}
	resp2, err := s.client.Do(req2)
	if err != nil {
		return ""
	}
	defer resp2.Body.Close()

	var shapeResp struct {
		Data struct {
			Entry struct {
				Points string `json:"points"`
			} `json:"entry"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp2.Body).Decode(&shapeResp); err != nil {
		return ""
	}
	return shapeResp.Data.Entry.Points
}
