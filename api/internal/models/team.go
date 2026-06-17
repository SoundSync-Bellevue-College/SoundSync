package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type TeamMember struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name        string             `bson:"name"          json:"name"`
	Pronouns    string             `bson:"pronouns"      json:"pronouns"`
	Role        string             `bson:"role"          json:"role"`
	PhotoURL    string             `bson:"photo_url"     json:"photo_url"`
	Quote       string             `bson:"quote"         json:"quote"`
	Description string             `bson:"description"   json:"description"`
	LinkedIn    string             `bson:"linkedin"      json:"linkedin"`
	GitHub      string             `bson:"github"        json:"github"`
	Instagram   string             `bson:"instagram"     json:"instagram"`
	SortOrder   int                `bson:"sort_order"    json:"sort_order"`
}
