package reports

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

type DelayReport struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	RouteID     string    `json:"routeId"`
	StopID      string    `json:"stopId"`
	DirectionID int       `json:"directionId"`
	VehicleID   string    `json:"vehicle_id"`
	ReportTime  time.Time `json:"report_time"`
	DelayMinute int       `json:"delay_minutes"`
}

type CreateDelayReportInput struct {
	RouteID     string
	StopID      string
	DirectionID int
	VehicleID   string
	ReportTime  time.Time
	DelayMinute int
}

type DelayReportFilter struct {
	RouteID     string
	StopID      string
	DirectionID *int
	Limit       int64
}

type delayReportDoc struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	UserID      primitive.ObjectID `bson:"userId"`
	RouteID     string             `bson:"routeId"`
	StopID      string             `bson:"stopId"`
	DirectionID int                `bson:"directionId"`
	VehicleID   string             `bson:"vehicle_id"`
	ReportTime  time.Time          `bson:"report_time"`
	DelayMinute int                `bson:"delay_minutes"`
}

type DelayService struct {
	coll *mongo.Collection
}

func NewDelayService(database *mongo.Database) (*DelayService, error) {
	s := &DelayService{coll: database.Collection("delay_reports")}
	if err := s.ensureIndexes(context.Background()); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *DelayService) Create(userID string, in CreateDelayReportInput) (DelayReport, error) {
	uid, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return DelayReport{}, errors.New("invalid user id")
	}

	in.RouteID = strings.TrimSpace(in.RouteID)
	in.StopID = strings.TrimSpace(in.StopID)
	in.VehicleID = strings.TrimSpace(in.VehicleID)

	if in.RouteID == "" || in.StopID == "" {
		return DelayReport{}, errors.New("routeId and stopId are required")
	}
	if in.DelayMinute < 0 {
		return DelayReport{}, errors.New("delay_minutes must be >= 0")
	}
	if in.ReportTime.IsZero() {
		in.ReportTime = time.Now().UTC()
	}

	doc := delayReportDoc{
		UserID:      uid,
		RouteID:     in.RouteID,
		StopID:      in.StopID,
		DirectionID: in.DirectionID,
		VehicleID:   in.VehicleID,
		ReportTime:  in.ReportTime.UTC(),
		DelayMinute: in.DelayMinute,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := s.coll.InsertOne(ctx, doc)
	if err != nil {
		return DelayReport{}, err
	}

	id, ok := result.InsertedID.(primitive.ObjectID)
	if !ok {
		return DelayReport{}, errors.New("failed to create report")
	}
	doc.ID = id
	return toDelayReport(doc), nil
}

func (s *DelayService) List(filter DelayReportFilter) ([]DelayReport, error) {
	mongoFilter := bson.M{}
	if routeID := strings.TrimSpace(filter.RouteID); routeID != "" {
		mongoFilter["routeId"] = routeID
	}
	if stopID := strings.TrimSpace(filter.StopID); stopID != "" {
		mongoFilter["stopId"] = stopID
	}
	if filter.DirectionID != nil {
		mongoFilter["directionId"] = *filter.DirectionID
	}

	limit := filter.Limit
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	opts := options.Find().SetSort(bson.D{{Key: "report_time", Value: -1}}).SetLimit(limit)
	cursor, err := s.coll.Find(ctx, mongoFilter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var docs []delayReportDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, err
	}

	out := make([]DelayReport, 0, len(docs))
	for _, d := range docs {
		out = append(out, toDelayReport(d))
	}
	return out, nil
}

func (s *DelayService) ensureIndexes(ctx context.Context) error {
	indexModels := []mongo.IndexModel{
		{Keys: bson.D{{Key: "routeId", Value: 1}, {Key: "directionId", Value: 1}, {Key: "stopId", Value: 1}, {Key: "report_time", Value: -1}}},
		{Keys: bson.D{{Key: "stopId", Value: 1}, {Key: "report_time", Value: -1}}},
		{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "report_time", Value: -1}}},
	}
	_, err := s.coll.Indexes().CreateMany(ctx, indexModels)
	return err
}

func toDelayReport(doc delayReportDoc) DelayReport {
	return DelayReport{
		ID:          doc.ID.Hex(),
		UserID:      doc.UserID.Hex(),
		RouteID:     doc.RouteID,
		StopID:      doc.StopID,
		DirectionID: doc.DirectionID,
		VehicleID:   doc.VehicleID,
		ReportTime:  doc.ReportTime,
		DelayMinute: doc.DelayMinute,
	}
}
