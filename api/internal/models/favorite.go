package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type PlaceRef struct {
	Name string  `bson:"name" json:"name"`
	Lat  float64 `bson:"lat"  json:"lat"`
	Lng  float64 `bson:"lng"  json:"lng"`
}

type FavoriteRoute struct {
	ID             primitive.ObjectID `bson:"_id,omitempty"    json:"_id"`
	UserID         primitive.ObjectID `bson:"userId"           json:"userId"`
	Label          string             `bson:"label"            json:"label"`
	Origin         PlaceRef           `bson:"origin"           json:"origin"`
	Destination    PlaceRef           `bson:"destination"      json:"destination"`
	TransitRouteIDs []string          `bson:"transitRouteIds"  json:"transitRouteIds"`
	CreatedAt      time.Time          `bson:"createdAt"        json:"createdAt"`
}
