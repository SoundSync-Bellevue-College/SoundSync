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

type FavoriteRepo struct {
	col *mongo.Collection
}

func NewFavoriteRepo(db *mongo.Database) *FavoriteRepo {
	return &FavoriteRepo{col: col(db, "favorite_routes")}
}

func (r *FavoriteRepo) Create(ctx context.Context, fav *models.FavoriteRoute) error {
	fav.ID = primitive.NewObjectID()
	fav.CreatedAt = time.Now()
	_, err := r.col.InsertOne(ctx, fav)
	return err
}

func (r *FavoriteRepo) FindByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.FavoriteRoute, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.col.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []models.FavoriteRoute
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}

func (r *FavoriteRepo) Delete(ctx context.Context, id primitive.ObjectID, userID primitive.ObjectID) error {
	_, err := r.col.DeleteOne(ctx, bson.M{"_id": id, "userId": userID})
	return err
}

func (r *FavoriteRepo) FindByRouteID(ctx context.Context, routeID string) ([]models.FavoriteRoute, error) {
	cursor, err := r.col.Find(ctx, bson.M{"transitRouteIds": routeID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []models.FavoriteRoute
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}
