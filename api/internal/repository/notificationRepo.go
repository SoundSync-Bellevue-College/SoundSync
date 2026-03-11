package repository

import (
	"context"
	"time"

	"soundsync/api/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type NotificationRepo struct {
	col *mongo.Collection
}

func NewNotificationRepo(db *mongo.Database) *NotificationRepo {
	return &NotificationRepo{col: col(db, "notifications")}
}

func (r *NotificationRepo) Create(ctx context.Context, n *models.Notification) error {
	n.ID = primitive.NewObjectID()
	n.CreatedAt = time.Now()
	_, err := r.col.InsertOne(ctx, n)
	return err
}

func (r *NotificationRepo) FindByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.Notification, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "read", Value: 1}, {Key: "createdAt", Value: -1}}).
		SetLimit(50)
	cursor, err := r.col.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []models.Notification
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}

func (r *NotificationRepo) MarkRead(ctx context.Context, id primitive.ObjectID, userID primitive.ObjectID) error {
	_, err := r.col.UpdateOne(ctx,
		bson.M{"_id": id, "userId": userID},
		bson.M{"$set": bson.M{"read": true}},
	)
	return err
}

func (r *NotificationRepo) MarkAllRead(ctx context.Context, userID primitive.ObjectID) error {
	_, err := r.col.UpdateMany(ctx,
		bson.M{"userId": userID, "read": false},
		bson.M{"$set": bson.M{"read": true}},
	)
	return err
}
