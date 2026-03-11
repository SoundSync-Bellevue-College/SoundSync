package repository

import (
	"context"
	"fmt"
	"sort"
	"time"

	"soundsync/api/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type VehicleReportRepo struct {
	cleanlinessCol *mongo.Collection
	crowdingCol    *mongo.Collection
	delayCol       *mongo.Collection
}

func NewVehicleReportRepo(db *mongo.Database) *VehicleReportRepo {
	return &VehicleReportRepo{
		cleanlinessCol: col(db, "vehicle_cleanliness_reports"),
		crowdingCol:    col(db, "vehicle_crowding_reports"),
		delayCol:       col(db, "vehicle_delay_reports"),
	}
}

func (r *VehicleReportRepo) CreateCleanliness(ctx context.Context, report *models.CleanlinessReport) error {
	report.ID = primitive.NewObjectID()
	report.CreatedAt = time.Now()
	_, err := r.cleanlinessCol.InsertOne(ctx, report)
	return err
}

func (r *VehicleReportRepo) CreateCrowding(ctx context.Context, report *models.CrowdingReport) error {
	report.ID = primitive.NewObjectID()
	report.CreatedAt = time.Now()
	_, err := r.crowdingCol.InsertOne(ctx, report)
	return err
}

func (r *VehicleReportRepo) CreateDelay(ctx context.Context, report *models.DelayReport) error {
	report.ID = primitive.NewObjectID()
	report.CreatedAt = time.Now()
	_, err := r.delayCol.InsertOne(ctx, report)
	return err
}

// FindByUserID queries all three report collections and returns a merged,
// date-descending list of VehicleReportSummary for the given user.
func (r *VehicleReportRepo) FindByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.VehicleReportSummary, error) {
	filter := bson.M{"userId": userID}
	opts := options.Find().SetSort(bson.M{"createdAt": -1})

	var results []models.VehicleReportSummary

	type entry struct {
		col      *mongo.Collection
		typeName string
	}
	for _, e := range []entry{
		{r.cleanlinessCol, "cleanliness"},
		{r.crowdingCol, "crowding"},
		{r.delayCol, "delay"},
	} {
		cur, err := e.col.Find(ctx, filter, opts)
		if err != nil {
			return nil, err
		}
		for cur.Next(ctx) {
			var s models.VehicleReportSummary
			if err := cur.Decode(&s); err == nil {
				s.Type = e.typeName
				results = append(results, s)
			}
		}
		cur.Close(ctx)
	}

	// Re-sort merged slice newest first
	sort.Slice(results, func(i, j int) bool {
		return results[i].CreatedAt.After(results[j].CreatedAt)
	})

	return results, nil
}

// DeleteByIDAndUser removes a single report document, verifying ownership.
func (r *VehicleReportRepo) DeleteByIDAndUser(ctx context.Context, reportType string, id primitive.ObjectID, userID primitive.ObjectID) error {
	var col *mongo.Collection
	switch reportType {
	case "cleanliness":
		col = r.cleanlinessCol
	case "crowding":
		col = r.crowdingCol
	case "delay":
		col = r.delayCol
	default:
		return fmt.Errorf("unknown report type: %s", reportType)
	}
	res, err := col.DeleteOne(ctx, bson.M{"_id": id, "userId": userID})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return fmt.Errorf("report not found or not owned by user")
	}
	return nil
}
