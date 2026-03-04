package notifications

import (
	"context"
	"errors"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type RouteSubscription struct {
	RouteID string `json:"routeId" bson:"routeId"`
}

type Preferences struct {
	Enabled       bool                `json:"enabled" bson:"enabled"`
	Subscriptions []RouteSubscription `json:"subscriptions" bson:"subscriptions"`
}

type userDoc struct {
	ID            primitive.ObjectID `bson:"_id"`
	Notifications Preferences        `bson:"notifications"`
}

type Service struct {
	usersColl *mongo.Collection
}

func NewService(database *mongo.Database) *Service {
	return &Service{usersColl: database.Collection("users")}
}

func (s *Service) GetPreferences(userID string) (Preferences, error) {
	id, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return Preferences{}, errors.New("invalid user id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var user userDoc
	err = s.usersColl.FindOne(ctx, bson.M{"_id": id}).Decode(&user)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return Preferences{}, errors.New("user not found")
		}
		return Preferences{}, err
	}
	return user.Notifications, nil
}

func (s *Service) SetEnabled(userID string, enabled bool) (Preferences, error) {
	id, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return Preferences{}, errors.New("invalid user id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	update := bson.M{
		"$set": bson.M{"notifications.enabled": enabled},
		"$setOnInsert": bson.M{
			"notifications.subscriptions": []RouteSubscription{},
		},
	}

	result := s.usersColl.FindOneAndUpdate(
		ctx,
		bson.M{"_id": id},
		update,
		options.FindOneAndUpdate().SetReturnDocument(options.After),
	)
	if err := result.Err(); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return Preferences{}, errors.New("user not found")
		}
		return Preferences{}, err
	}

	var user userDoc
	if err := result.Decode(&user); err != nil {
		return Preferences{}, err
	}
	return user.Notifications, nil
}

func (s *Service) Subscribe(userID, routeID string) (Preferences, error) {
	id, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return Preferences{}, errors.New("invalid user id")
	}
	routeID = strings.TrimSpace(routeID)
	if routeID == "" {
		return Preferences{}, errors.New("routeId is required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	update := bson.M{
		"$addToSet":    bson.M{"notifications.subscriptions": bson.M{"routeId": routeID}},
		"$setOnInsert": bson.M{"notifications.enabled": true},
	}
	result := s.usersColl.FindOneAndUpdate(
		ctx,
		bson.M{"_id": id},
		update,
		options.FindOneAndUpdate().SetReturnDocument(options.After),
	)
	if err := result.Err(); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return Preferences{}, errors.New("user not found")
		}
		return Preferences{}, err
	}

	var user userDoc
	if err := result.Decode(&user); err != nil {
		return Preferences{}, err
	}
	return user.Notifications, nil
}

func (s *Service) Unsubscribe(userID, routeID string) (Preferences, error) {
	id, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return Preferences{}, errors.New("invalid user id")
	}
	routeID = strings.TrimSpace(routeID)
	if routeID == "" {
		return Preferences{}, errors.New("routeId is required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	update := bson.M{"$pull": bson.M{"notifications.subscriptions": bson.M{"routeId": routeID}}}
	result := s.usersColl.FindOneAndUpdate(
		ctx,
		bson.M{"_id": id},
		update,
		options.FindOneAndUpdate().SetReturnDocument(options.After),
	)
	if err := result.Err(); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return Preferences{}, errors.New("user not found")
		}
		return Preferences{}, err
	}

	var user userDoc
	if err := result.Decode(&user); err != nil {
		return Preferences{}, err
	}
	return user.Notifications, nil
}
