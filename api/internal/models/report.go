package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type LatLng struct {
	Lat float64 `bson:"lat" json:"lat"`
	Lng float64 `bson:"lng" json:"lng"`
}

type Report struct {
	ID          primitive.ObjectID  `bson:"_id,omitempty" json:"_id"`
	UserID      primitive.ObjectID  `bson:"userId"        json:"userId"`
	RouteID     string              `bson:"routeId"       json:"routeId"`
	VehicleID   string              `bson:"vehicleId"     json:"vehicleId,omitempty"`
	Type        string              `bson:"type"          json:"type"`
	Severity    string              `bson:"severity"      json:"severity"`
	Description string              `bson:"description"   json:"description,omitempty"`
	Location    *LatLng             `bson:"location"      json:"location,omitempty"`
	CreatedAt   time.Time           `bson:"createdAt"     json:"createdAt"`
}
