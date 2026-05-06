package services

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"strings"
	"sync"
	"time"

	"soundsync/api/internal/config"
	"soundsync/api/internal/models"
	gtfs "soundsync/api/pkg/gtfs"
)

type TransitService struct {
	cfg         *config.Config
	vehiclesMu  sync.RWMutex
	vehicles    []models.VehiclePosition
	lastFetched time.Time
}

func NewTransitService(cfg *config.Config) *TransitService {
	return &TransitService{cfg: cfg}
}

// GetVehicles returns cached vehicle positions, refreshing every 15 s.
func (s *TransitService) GetVehicles(ctx context.Context) ([]models.VehiclePosition, error) {
	s.vehiclesMu.Lock()
	defer s.vehiclesMu.Unlock()

	if time.Since(s.lastFetched) < 15*time.Second && len(s.vehicles) > 0 {
		return s.vehicles, nil
	}

	vehicles, err := s.loadVehicles(ctx)
	if err != nil {
		log.Printf("vehicle fetch error: %v — serving cached data", err)
		if len(s.vehicles) > 0 {
			return s.vehicles, nil
		}
		return devMockVehicles(), nil
	}

	if len(vehicles) == 0 {
		log.Printf("all vehicle sources returned 0 — using dev mock vehicles")
		vehicles = devMockVehicles()
	}

	s.vehicles = deduplicateVehicles(vehicles)
	s.lastFetched = time.Now()
	return s.vehicles, nil
}

// railRouteIDs maps known Sound Transit rail/streetcar/ferry route IDs to their type.
// Route IDs here are the short form used after stripping the agency prefix from OBA trip IDs.
var railRouteIDs = map[string]string{
	// Link Light Rail
	"1 Line": "RAIL", "2 Line": "RAIL",
	"1_Line": "RAIL", "2_Line": "RAIL",
	"599": "RAIL", "100479": "RAIL",
	// Sounder commuter rail
	"Sounder-North": "RAIL", "Sounder-South": "RAIL",
	"Sounder_N": "RAIL", "Sounder_S": "RAIL",
	// Seattle Streetcar
	"100340": "STREETCAR", "102638": "STREETCAR",
	// King County Water Taxi
	"100336": "FERRY", "100337": "FERRY",
}

// routeTypeFor returns a human-readable vehicle category for a given routeID.
func routeTypeFor(routeID string) string {
	if t, ok := railRouteIDs[routeID]; ok {
		return t
	}
	return "BUS"
}

// loadVehicles tries data sources in order: GTFS-RT → OBA REST → empty.
func (s *TransitService) loadVehicles(ctx context.Context) ([]models.VehiclePosition, error) {
	var buses, rail []models.VehiclePosition

	// ── 1. KCM GTFS-RT feed (buses) ──────────────────────────────────────────
	if s.cfg.GTFSVehicleURL != "" {
		v, err := s.fetchFromGTFS(ctx, s.cfg.GTFSVehicleURL)
		if err != nil {
			log.Printf("KCM GTFS-RT feed error: %v", err)
		} else {
			tagRouteTypes(v)
			log.Printf("Loaded %d vehicles from KCM GTFS-RT", len(v))
			buses = v
		}
	}

	// ── 2. Sound Transit GTFS-RT feed (rail + ST express) ────────────────────
	if s.cfg.GTFSRailVehicleURL != "" {
		v, err := s.fetchFromGTFS(ctx, s.cfg.GTFSRailVehicleURL)
		if err != nil {
			log.Printf("ST GTFS-RT feed error: %v", err)
		} else {
			tagRouteTypes(v)
			log.Printf("Loaded %d vehicles from ST GTFS-RT", len(v))
			rail = v
		}
	}

	// ── 3. OBA REST API fallback ──────────────────────────────────────────────
	if len(buses) == 0 && len(rail) == 0 {
		v, err := s.fetchFromOBA(ctx)
		if err != nil {
			log.Printf("OBA API error: %v", err)
			return nil, err
		}
		tagRouteTypes(v)
		log.Printf("Loaded %d vehicles from OBA", len(v))
		return v, nil
	}

	combined := make([]models.VehiclePosition, 0, len(buses)+len(rail))
	combined = append(combined, buses...)
	combined = append(combined, rail...)
	return combined, nil
}

// tagRouteTypes sets RouteType on each vehicle based on its RouteID.
func tagRouteTypes(vehicles []models.VehiclePosition) {
	for i := range vehicles {
		vehicles[i].RouteType = routeTypeFor(vehicles[i].RouteID)
	}
}

// deduplicateVehicles removes vehicles with duplicate VehicleIDs, keeping the first occurrence.
func deduplicateVehicles(vehicles []models.VehiclePosition) []models.VehiclePosition {
	seen := make(map[string]struct{}, len(vehicles))
	out := vehicles[:0]
	for _, v := range vehicles {
		if _, dup := seen[v.VehicleID]; dup {
			continue
		}
		seen[v.VehicleID] = struct{}{}
		out = append(out, v)
	}
	return out
}

// fetchFromGTFS downloads and parses a GTFS-RT vehicle positions feed at the given URL.
func (s *TransitService) fetchFromGTFS(ctx context.Context, url string) ([]models.VehiclePosition, error) {
	data, err := fetchFeed(ctx, url)
	if err != nil {
		return nil, fmt.Errorf("download GTFS feed: %w", err)
	}

	if strings.HasSuffix(url, ".json") {
		feed, err := gtfs.ParseVehiclePositionsJSON(data)
		if err != nil {
			return nil, fmt.Errorf("parse GTFS JSON: %w", err)
		}
		return feed, nil
	}

	feed, err := gtfs.ParseVehiclePositions(data)
	if err != nil {
		return nil, fmt.Errorf("parse GTFS protobuf: %w", err)
	}
	return feed, nil
}

// obaAgenciesResponse mirrors the OBA REST /vehicles-for-agency response.
type obaAgenciesResponse struct {
	Code int `json:"code"`
	Data struct {
		List []struct {
			VehicleID             string `json:"vehicleId"`
			TripID                string `json:"tripId"`
			LastLocationUpdateTime int64 `json:"lastLocationUpdateTime"`
			Location              struct {
				Lat float64 `json:"lat"`
				Lon float64 `json:"lon"`
			} `json:"location"`
			TripStatus *struct {
				ActiveTripID string `json:"activeTripId"`
				ClosestStop  string `json:"closestStop"`
				Position     *struct {
					Lat float64 `json:"lat"`
					Lon float64 `json:"lon"`
				} `json:"position"`
			} `json:"tripStatus"`
		} `json:"list"`
	} `json:"data"`
}

// fetchFromOBA calls the OneBusAway Puget Sound REST API for live vehicle positions.
// Agency 1 = King County Metro + Sound Transit vehicles tracked by OBA.
func (s *TransitService) fetchFromOBA(ctx context.Context) ([]models.VehiclePosition, error) {
	url := fmt.Sprintf(
		"%s/api/where/vehicles-for-agency/1.json?key=%s",
		s.cfg.OBABaseURL, s.cfg.OBAApiKey,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("OBA request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, fmt.Errorf("OBA rate-limited (429) — use a real API key via OBA_API_KEY")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OBA returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var obaResp obaAgenciesResponse
	if err := json.Unmarshal(body, &obaResp); err != nil {
		return nil, fmt.Errorf("decode OBA response: %w", err)
	}

	if obaResp.Code != 200 {
		return nil, fmt.Errorf("OBA response code %d", obaResp.Code)
	}

	vehicles := make([]models.VehiclePosition, 0, len(obaResp.Data.List))
	for _, v := range obaResp.Data.List {
		lat := v.Location.Lat
		lng := v.Location.Lon

		// Prefer the more precise tripStatus position when available
		if v.TripStatus != nil && v.TripStatus.Position != nil {
			lat = v.TripStatus.Position.Lat
			lng = v.TripStatus.Position.Lon
		}

		// Skip vehicles with no valid position
		if lat == 0 && lng == 0 {
			continue
		}

		// Parse agency prefix from vehicleId "1_7192" → vehicleNum "7192"
		vehicleNum := v.VehicleID
		if idx := strings.Index(v.VehicleID, "_"); idx >= 0 {
			vehicleNum = v.VehicleID[idx+1:]
		}

		// Extract routeId from tripId if available ("1_100001_..." → "100001")
		routeID := ""
		if v.TripID != "" {
			parts := strings.SplitN(v.TripID, "_", 3)
			if len(parts) >= 2 {
				routeID = parts[1]
			}
		}

		var ts string
		if v.LastLocationUpdateTime > 0 {
			ts = time.Unix(v.LastLocationUpdateTime/1000, 0).UTC().Format(time.RFC3339)
		} else {
			ts = time.Now().UTC().Format(time.RFC3339)
		}

		vehicles = append(vehicles, models.VehiclePosition{
			VehicleID: vehicleNum,
			RouteID:   routeID,
			TripID:    v.TripID,
			Lat:       lat,
			Lng:       lng,
			Timestamp: ts,
		})
	}

	return vehicles, nil
}

// devMockVehicles returns a realistic set of Seattle-area vehicles (buses + rail)
// used as a last resort when all live sources return nothing.
func devMockVehicles() []models.VehiclePosition {
	now := time.Now().UTC().Format(time.RFC3339)
	return []models.VehiclePosition{
		// KCM buses
		{VehicleID: "9301", RouteID: "100252", TripID: "mock-001", Lat: 47.6062, Lng: -122.3321, Bearing: 90, Speed: 14.5, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "BUS"},
		{VehicleID: "9302", RouteID: "100194", TripID: "mock-002", Lat: 47.6253, Lng: -122.3222, Bearing: 180, Speed: 10.2, Timestamp: now, OccupancyStatus: "FEW_SEATS_AVAILABLE", RouteType: "BUS"},
		{VehicleID: "9304", RouteID: "100252", TripID: "mock-004", Lat: 47.6150, Lng: -122.3450, Bearing: 270, Speed: 12.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "BUS"},
		{VehicleID: "9305", RouteID: "100194", TripID: "mock-005", Lat: 47.6350, Lng: -122.3100, Bearing: 45, Speed: 8.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "BUS"},
		// Link 1 Line — southbound through downtown toward Rainier Valley
		{VehicleID: "L101", RouteID: "1 Line", TripID: "mock-L101", Lat: 47.6110, Lng: -122.3374, Bearing: 180, Speed: 35.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "RAIL"},
		{VehicleID: "L102", RouteID: "1 Line", TripID: "mock-L102", Lat: 47.5795, Lng: -122.3269, Bearing: 180, Speed: 40.0, Timestamp: now, OccupancyStatus: "FEW_SEATS_AVAILABLE", RouteType: "RAIL"},
		// Link 1 Line — northbound toward UW / Northgate
		{VehicleID: "L103", RouteID: "1 Line", TripID: "mock-L103", Lat: 47.6499, Lng: -122.3043, Bearing: 0, Speed: 38.0, Timestamp: now, OccupancyStatus: "STANDING_ROOM_ONLY", RouteType: "RAIL"},
		{VehicleID: "L104", RouteID: "1 Line", TripID: "mock-L104", Lat: 47.7063, Lng: -122.3224, Bearing: 0, Speed: 42.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "RAIL"},
		// Link 2 Line — eastbound to Bellevue/Redmond
		{VehicleID: "L201", RouteID: "2 Line", TripID: "mock-L201", Lat: 47.5980, Lng: -122.3280, Bearing: 90, Speed: 36.0, Timestamp: now, OccupancyStatus: "FEW_SEATS_AVAILABLE", RouteType: "RAIL"},
		{VehicleID: "L202", RouteID: "2 Line", TripID: "mock-L202", Lat: 47.6162, Lng: -122.1999, Bearing: 90, Speed: 44.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "RAIL"},
		// Link 2 Line — westbound back to Seattle
		{VehicleID: "L203", RouteID: "2 Line", TripID: "mock-L203", Lat: 47.6193, Lng: -122.0989, Bearing: 270, Speed: 44.0, Timestamp: now, OccupancyStatus: "MANY_SEATS_AVAILABLE", RouteType: "RAIL"},
	}
}

// GetNearbyStops returns stops within radius meters of lat/lng via the OBA API.
func (s *TransitService) GetNearbyStops(ctx context.Context, lat, lng float64, radius int) ([]map[string]interface{}, error) {
	url := fmt.Sprintf(
		"%s/api/where/stops-for-location.json?key=%s&lat=%f&lon=%f&radius=%d",
		s.cfg.OBABaseURL, s.cfg.OBAApiKey, lat, lng, radius,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OBA stops returned status %d", resp.StatusCode)
	}

	var result struct {
		Data struct {
			List []struct {
				ID       string   `json:"id"`
				Name     string   `json:"name"`
				Lat      float64  `json:"lat"`
				Lon      float64  `json:"lon"`
				RouteIDs []string `json:"routeIds"`
			} `json:"list"`
		} `json:"data"`
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	stops := make([]map[string]interface{}, 0, len(result.Data.List))
	for _, s := range result.Data.List {
		stops = append(stops, map[string]interface{}{
			"stopId": s.ID,
			"name":   s.Name,
			"lat":    s.Lat,
			"lng":    s.Lon,
			"routes": s.RouteIDs,
		})
	}
	return stops, nil
}

// GetArrivals returns upcoming arrivals for a stop via the OBA API.
func (s *TransitService) GetArrivals(ctx context.Context, stopID string) ([]map[string]interface{}, error) {
	url := fmt.Sprintf(
		"%s/api/where/arrivals-and-departures-for-stop/%s.json?key=%s&minutesAfter=90",
		s.cfg.OBABaseURL, stopID, s.cfg.OBAApiKey,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OBA arrivals returned status %d", resp.StatusCode)
	}

	var result struct {
		Data struct {
			Entry struct {
				ArrivalsAndDepartures []struct {
					TripID                string `json:"tripId"`
					RouteID               string `json:"routeId"`
					RouteShortName        string `json:"routeShortName"`
					TripHeadsign          string `json:"tripHeadsign"`
					ScheduledArrivalTime  int64  `json:"scheduledArrivalTime"`
					PredictedArrivalTime  int64  `json:"predictedArrivalTime"`
				} `json:"arrivalsAndDepartures"`
			} `json:"entry"`
		} `json:"data"`
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	arrivals := make([]map[string]interface{}, 0)
	for _, a := range result.Data.Entry.ArrivalsAndDepartures {
		if a.ScheduledArrivalTime == 0 {
			continue
		}

		scheduled := time.UnixMilli(a.ScheduledArrivalTime).UTC().Format(time.RFC3339)
		var estimated *string
		var delaySec int64
		status := "UNKNOWN"

		if a.PredictedArrivalTime != 0 {
			est := time.UnixMilli(a.PredictedArrivalTime).UTC().Format(time.RFC3339)
			estimated = &est
			delaySec = (a.PredictedArrivalTime - a.ScheduledArrivalTime) / 1000
			switch {
			case delaySec > 60:
				status = "DELAYED"
			case delaySec < -60:
				status = "EARLY"
			default:
				status = "ON_TIME"
			}
		} else {
			status = "ON_TIME"
		}

		entry := map[string]interface{}{
			"tripId":           a.TripID,
			"routeId":          a.RouteID,
			"routeShortName":   a.RouteShortName,
			"headsign":         a.TripHeadsign,
			"scheduledArrival": scheduled,
			"delaySeconds":     delaySec,
			"status":           status,
		}
		if estimated != nil {
			entry["estimatedArrival"] = *estimated
		}
		arrivals = append(arrivals, entry)
	}
	return arrivals, nil
}

func fetchFeed(ctx context.Context, url string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

// haversineDistance returns distance in meters between two lat/lng points.
func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	return R * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

var _ = haversineDistance
