package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	ID                   primitive.ObjectID `bson:"_id,omitempty"          json:"id"`
	Email                string             `bson:"email"                  json:"email"`
	PasswordHash         string             `bson:"passwordHash"           json:"-"`
	DisplayName          string             `bson:"displayName"            json:"displayName"`
	NotificationsEnabled bool               `bson:"notificationsEnabled"   json:"notificationsEnabled"`
	TempUnit             string             `bson:"tempUnit"               json:"tempUnit"`     // "F" or "C"
	DistanceUnit         string             `bson:"distanceUnit"           json:"distanceUnit"` // "mi" or "km"
	Deleted              bool               `bson:"deleted"                json:"-"`
	DeletedAt            *time.Time         `bson:"deletedAt,omitempty"    json:"-"`
	CreatedAt            time.Time          `bson:"createdAt"              json:"createdAt"`
	UpdatedAt            time.Time          `bson:"updatedAt"              json:"updatedAt"`
}
