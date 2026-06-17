package repository

import (
	"context"

	"soundsync/api/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type TeamRepo struct {
	col *mongo.Collection
}

func NewTeamRepo(db *mongo.Database) *TeamRepo {
	return &TeamRepo{col: db.Collection("team_members")}
}

func (r *TeamRepo) GetAll(ctx context.Context) ([]models.TeamMember, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sort_order", Value: 1}})
	cur, err := r.col.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var members []models.TeamMember
	if err := cur.All(ctx, &members); err != nil {
		return nil, err
	}
	return members, nil
}

func (r *TeamRepo) Upsert(ctx context.Context, m models.TeamMember) error {
	filter := bson.M{"name": m.Name}
	update := bson.M{"$set": bson.M{
		"pronouns":    m.Pronouns,
		"role":        m.Role,
		"photo_url":   m.PhotoURL,
		"quote":       m.Quote,
		"description": m.Description,
		"linkedin":    m.LinkedIn,
		"github":      m.GitHub,
		"instagram":   m.Instagram,
		"sort_order":  m.SortOrder,
	}, "$setOnInsert": bson.M{"_id": primitive.NewObjectID()}}
	opts := options.Update().SetUpsert(true)
	_, err := r.col.UpdateOne(ctx, filter, update, opts)
	return err
}
