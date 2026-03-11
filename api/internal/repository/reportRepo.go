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

type ReportRepo struct {
	col *mongo.Collection
}

func NewReportRepo(db *mongo.Database) *ReportRepo {
	return &ReportRepo{col: col(db, "reports")}
}

func (r *ReportRepo) Create(ctx context.Context, report *models.Report) error {
	report.ID = primitive.NewObjectID()
	report.CreatedAt = time.Now()
	_, err := r.col.InsertOne(ctx, report)
	return err
}

func (r *ReportRepo) FindByRouteID(ctx context.Context, routeID string) ([]models.Report, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}}).SetLimit(50)
	cursor, err := r.col.Find(ctx, bson.M{"routeId": routeID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []models.Report
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}
