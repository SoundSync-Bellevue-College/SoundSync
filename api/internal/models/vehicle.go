package models

// VehiclePosition represents a real-time vehicle location decoded from GTFS-RT.
type VehiclePosition struct {
	VehicleID       string  `json:"vehicleId"`
	RouteID         string  `json:"routeId"`
	TripID          string  `json:"tripId"`
	Lat             float64 `json:"lat"`
	Lng             float64 `json:"lng"`
	Bearing         float32 `json:"bearing"`
	Speed           float32 `json:"speed"`
	Timestamp       string  `json:"timestamp"`
	OccupancyStatus string  `json:"occupancyStatus,omitempty"`
}
