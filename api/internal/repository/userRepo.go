package repository

import (
	"context"
	"time"

	"soundsync/api/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type UserRepo struct {
	col *mongo.Collection
}

func NewUserRepo(db *mongo.Database) *UserRepo {
	return &UserRepo{col: col(db, "users")}
}

func (r *UserRepo) Create(ctx context.Context, user *models.User) error {
	user.ID = primitive.NewObjectID()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()
	_, err := r.col.InsertOne(ctx, user)
	return err
}

func (r *UserRepo) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	err := r.col.FindOne(ctx, bson.M{"email": email, "deleted": bson.M{"$ne": true}}).Decode(&user)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) FindByID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
	var user models.User
	err := r.col.FindOne(ctx, bson.M{"_id": id, "deleted": bson.M{"$ne": true}}).Decode(&user)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) Update(ctx context.Context, id primitive.ObjectID, fields bson.M) error {
	fields["updatedAt"] = time.Now()
	_, err := r.col.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": fields})
	return err
}

// SoftDelete marks the user as deleted without removing the document.
func (r *UserRepo) SoftDelete(ctx context.Context, id primitive.ObjectID) error {
	now := time.Now()
	_, err := r.col.UpdateOne(
		ctx,
		bson.M{"_id": id},
		bson.M{"$set": bson.M{
			"deleted":   true,
			"deletedAt": now,
			"updatedAt": now,
		}},
	)
	return err
}
