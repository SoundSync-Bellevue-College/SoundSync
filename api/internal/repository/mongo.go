package repository

import "go.mongodb.org/mongo-driver/mongo"

// colName is a helper to get a collection from a database.
func col(db *mongo.Database, name string) *mongo.Collection {
	return db.Collection(name)
}
