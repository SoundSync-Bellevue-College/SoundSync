package predictions

import (
	"context"
	"math"
	"sort"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// timeBin classifies an hour of day (0-23) into a named period.
func timeBin(hour int) string {
	switch {
	case hour >= 6 && hour < 9:
		return "morning"
	case hour >= 9 && hour < 15:
		return "midday"
	case hour >= 15 && hour < 18:
		return "afternoon"
	case hour >= 18 && hour < 21:
		return "evening"
	default:
		return "night"
	}
}

// dayType returns "weekday" or "weekend".
func dayType(wd time.Weekday) string {
	if wd == time.Saturday || wd == time.Sunday {
		return "weekend"
	}
	return "weekday"
}

// confidence converts a sample count into a 0–1 score.
// < 3 → low (≤0.35), 3–9 → medium (≤0.70), ≥10 → high (≤1.0).
func confidence(n int) float64 {
	if n <= 0 {
		return 0
	}
	// Asymptotically approaches 1.0; reaches ~0.9 at n=20.
	return 1.0 - math.Exp(-float64(n)/10.0)
}

// DelayPrediction is the result of a delay forecast query.
type DelayPrediction struct {
	RouteID              string  `json:"routeId"`
	StopID               string  `json:"stopId"`
	DirectionID          int     `json:"directionId"`
	PredictedDelayMin    float64 `json:"predicted_delay_minutes"`
	Percentile90DelayMin float64 `json:"percentile_90_delay_minutes"`
	Confidence           float64 `json:"confidence"`
	SampleSize           int     `json:"sample_size"`
	TimeBin              string  `json:"time_bin"`
	DayType              string  `json:"day_type"`
}

// CrowdingPrediction is the result of a crowding forecast query.
type CrowdingPrediction struct {
	RouteID           string  `json:"routeId"`
	StopID            string  `json:"stopId"`
	DirectionID       int     `json:"directionId"`
	PredictedLevel    float64 `json:"predicted_crowding_level"`
	Percentile90Level float64 `json:"percentile_90_crowding_level"`
	Confidence        float64 `json:"confidence"`
	SampleSize        int     `json:"sample_size"`
	TimeBin           string  `json:"time_bin"`
	DayType           string  `json:"day_type"`
}

// PredictionInput describes what to predict for.
type PredictionInput struct {
	RouteID     string
	StopID      string
	DirectionID *int
	// At is the reference time used to determine time-bin and day-type.
	// Defaults to time.Now() when zero.
	At time.Time
}

// Service performs statistical predictions over historical report data.
type Service struct {
	delayReports     *mongo.Collection
	crowdingReports  *mongo.Collection
}

// NewService creates a PredictionService backed by the given database.
func NewService(database *mongo.Database) *Service {
	return &Service{
		delayReports:    database.Collection("delay_reports"),
		crowdingReports: database.Collection("crowding_reports"),
	}
}

// PredictDelay returns a delay prediction for the given route/stop combination.
func (s *Service) PredictDelay(in PredictionInput) (DelayPrediction, error) {
	at := in.At
	if at.IsZero() {
		at = time.Now().UTC()
	}
	bin := timeBin(at.Hour())
	dt := dayType(at.Weekday())

	values, err := s.fetchDelayValues(in, bin, dt)
	if err != nil {
		return DelayPrediction{}, err
	}

	dirID := 0
	if in.DirectionID != nil {
		dirID = *in.DirectionID
	}

	pred := DelayPrediction{
		RouteID:     strings.TrimSpace(in.RouteID),
		StopID:      strings.TrimSpace(in.StopID),
		DirectionID: dirID,
		TimeBin:     bin,
		DayType:     dt,
		SampleSize:  len(values),
		Confidence:  confidence(len(values)),
	}

	if len(values) > 0 {
		pred.PredictedDelayMin = mean(values)
		pred.Percentile90DelayMin = percentile(values, 90)
	}

	return pred, nil
}

// PredictCrowding returns a crowding prediction for the given route/stop combination.
func (s *Service) PredictCrowding(in PredictionInput) (CrowdingPrediction, error) {
	at := in.At
	if at.IsZero() {
		at = time.Now().UTC()
	}
	bin := timeBin(at.Hour())
	dt := dayType(at.Weekday())

	values, err := s.fetchCrowdingValues(in, bin, dt)
	if err != nil {
		return CrowdingPrediction{}, err
	}

	dirID := 0
	if in.DirectionID != nil {
		dirID = *in.DirectionID
	}

	pred := CrowdingPrediction{
		RouteID:     strings.TrimSpace(in.RouteID),
		StopID:      strings.TrimSpace(in.StopID),
		DirectionID: dirID,
		TimeBin:     bin,
		DayType:     dt,
		SampleSize:  len(values),
		Confidence:  confidence(len(values)),
	}

	if len(values) > 0 {
		pred.PredictedLevel = mean(values)
		pred.Percentile90Level = percentile(values, 90)
	}

	return pred, nil
}

// fetchDelayValues queries delay_reports and returns all matching delay_minutes
// values for the same time-bin and day-type over the past 90 days.
func (s *Service) fetchDelayValues(in PredictionInput, bin, dt string) ([]float64, error) {
	filter := s.buildFilter(in)
	since := time.Now().UTC().AddDate(0, 0, -90)
	filter["report_time"] = bson.M{"$gte": since}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := s.delayReports.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	type row struct {
		ReportTime  time.Time `bson:"report_time"`
		DelayMinute int       `bson:"delay_minutes"`
	}

	var values []float64
	for cursor.Next(ctx) {
		var r row
		if err := cursor.Decode(&r); err != nil {
			continue
		}
		if timeBin(r.ReportTime.UTC().Hour()) == bin && dayType(r.ReportTime.UTC().Weekday()) == dt {
			values = append(values, float64(r.DelayMinute))
		}
	}
	return values, cursor.Err()
}

// fetchCrowdingValues queries crowding_reports and returns all matching
// crowding_level values for the same time-bin and day-type over the past 90 days.
func (s *Service) fetchCrowdingValues(in PredictionInput, bin, dt string) ([]float64, error) {
	filter := s.buildFilter(in)
	since := time.Now().UTC().AddDate(0, 0, -90)
	filter["report_time"] = bson.M{"$gte": since}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := s.crowdingReports.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	type row struct {
		ReportTime    time.Time `bson:"report_time"`
		CrowdingLevel int       `bson:"crowding_level"`
	}

	var values []float64
	for cursor.Next(ctx) {
		var r row
		if err := cursor.Decode(&r); err != nil {
			continue
		}
		if timeBin(r.ReportTime.UTC().Hour()) == bin && dayType(r.ReportTime.UTC().Weekday()) == dt {
			values = append(values, float64(r.CrowdingLevel))
		}
	}
	return values, cursor.Err()
}

// buildFilter constructs the base MongoDB filter from PredictionInput.
func (s *Service) buildFilter(in PredictionInput) bson.M {
	filter := bson.M{}
	if routeID := strings.TrimSpace(in.RouteID); routeID != "" {
		filter["routeId"] = routeID
	}
	if stopID := strings.TrimSpace(in.StopID); stopID != "" {
		filter["stopId"] = stopID
	}
	if in.DirectionID != nil {
		filter["directionId"] = *in.DirectionID
	}
	return filter
}

// mean returns the arithmetic mean of a slice.
func mean(vals []float64) float64 {
	if len(vals) == 0 {
		return 0
	}
	var sum float64
	for _, v := range vals {
		sum += v
	}
	return math.Round(sum/float64(len(vals))*100) / 100
}

// percentile returns the p-th percentile (0–100) of a slice using nearest-rank.
func percentile(vals []float64, p float64) float64 {
	if len(vals) == 0 {
		return 0
	}
	sorted := make([]float64, len(vals))
	copy(sorted, vals)
	sort.Float64s(sorted)

	idx := int(math.Ceil(p/100.0*float64(len(sorted)))) - 1
	if idx < 0 {
		idx = 0
	}
	if idx >= len(sorted) {
		idx = len(sorted) - 1
	}
	return math.Round(sorted[idx]*100) / 100
}
