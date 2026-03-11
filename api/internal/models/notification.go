package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Notification struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID     primitive.ObjectID `bson:"userId"        json:"userId"`
	RouteID    string             `bson:"routeId"       json:"routeId"`
	ReportType string             `bson:"reportType"    json:"reportType"`
	Message    string             `bson:"message"       json:"message"`
	Read       bool               `bson:"read"          json:"read"`
	CreatedAt  time.Time          `bson:"createdAt"     json:"createdAt"`
}
