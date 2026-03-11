package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"soundsync/api/internal/config"
	"soundsync/api/internal/router"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func New(cfg *config.Config) *http.Server {
	db := connectMongo(cfg)

	r := router.New(cfg, db)

	return &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
}

func connectMongo(cfg *config.Config) *mongo.Database {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOpts := options.Client().ApplyURI(cfg.MongoURI)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		log.Fatalf("MongoDB connect error: %v", err)
	}

	if err := client.Ping(ctx, nil); err != nil {
		log.Fatalf("MongoDB ping error: %v", err)
	}

	log.Printf("Connected to MongoDB: %s", cfg.MongoDB)
	return client.Database(cfg.MongoDB)
}
