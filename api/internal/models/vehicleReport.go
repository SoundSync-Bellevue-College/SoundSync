package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// VehicleReportSummary is the unified shape returned by GET /users/me/reports.
type VehicleReportSummary struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Type      string             `bson:"-"             json:"type"` // "cleanliness" | "crowding" | "delay"
	VehicleID string             `bson:"vehicleId"     json:"vehicleId"`
	RouteID   string             `bson:"routeId"       json:"routeId"`
	Level     int                `bson:"level"         json:"level"`
	CreatedAt time.Time          `bson:"createdAt"     json:"createdAt"`
}

// CleanlinessReport — level 1 (very dirty) to 5 (very clean)
// Collection: vehicle_cleanliness_reports
type CleanlinessReport struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"userId"        json:"userId"`
	VehicleID string             `bson:"vehicleId"     json:"vehicleId"`
	RouteID   string             `bson:"routeId"       json:"routeId"`
	Level     int                `bson:"level"         json:"level"`
	CreatedAt time.Time          `bson:"createdAt"     json:"createdAt"`
}

// CrowdingReport — level 1 (empty) to 5 (packed)
// Collection: vehicle_crowding_reports
type CrowdingReport struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"userId"        json:"userId"`
	VehicleID string             `bson:"vehicleId"     json:"vehicleId"`
	RouteID   string             `bson:"routeId"       json:"routeId"`
	Level     int                `bson:"level"         json:"level"`
	CreatedAt time.Time          `bson:"createdAt"     json:"createdAt"`
}

// DelayReport — level 1 (on time) to 5 (very delayed)
// Collection: vehicle_delay_reports
type DelayReport struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"userId"        json:"userId"`
	VehicleID string             `bson:"vehicleId"     json:"vehicleId"`
	RouteID   string             `bson:"routeId"       json:"routeId"`
	Level     int                `bson:"level"         json:"level"`
	CreatedAt time.Time          `bson:"createdAt"     json:"createdAt"`
}
