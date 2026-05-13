package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"

	"soundsync/api/internal/config"
)

// OBA-format route IDs (agency prefix + numeric ID) — matches what the poller stores
var obaRouteIDs = []string{
	"1_100001", "1_100002", "1_100252", "1_100194", "1_100339", "1_100512",
	"1_102548", "1_102576", "1_102616",
}

var stopIDs = []string{
	"1_67652", "1_68007", "1_68001", "1_68006", "1_69021",
	"3_12339", "3_8468", "1_67640", "1_67650", "1_67720",
}

var headsigns = []string{
	"Downtown Seattle", "Bellevue TC", "Redmond TC", "Eastgate P&R",
	"Issaquah TC", "Overlake TC", "South Bellevue", "Mercer Island",
}

// MongoDB pools
var (
	vehicleIDs = []string{"9301", "9302", "9304", "9305", "L101", "L102", "L103", "L104"}
	routeIDs   = []string{"100001", "100002", "100252", "100194", "100339", "100512"}

	reportTypes        = []string{"delay", "breakdown", "safety", "other"}
	reportSeverities   = []string{"low", "medium", "high"}
	reportDescriptions = []string{
		"Bus was significantly late.",
		"Vehicle broke down mid-route.",
		"Felt unsafe due to erratic driving.",
		"Driver was rude to passengers.",
		"Bus skipped my stop.",
		"Route deviated from schedule.",
	}
)

func main() {
	numUsers     := flag.Int("users", 25, "number of seed users to create")
	numArrivals  := flag.Int("arrivals", 300, "number of fake arrival rows to insert per route")
	flag.Parse()

	// Load env (try monorepo root first, then local .env)
	for _, p := range []string{"../.env", ".env"} {
		if err := godotenv.Load(p); err == nil {
			log.Printf("Loaded env from %s", p)
			break
		}
	}

	cfg := config.Load()
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	// ── MongoDB ──────────────────────────────────────────────────────────────
	ctx := context.Background()
	clientOpts := options.Client().ApplyURI(cfg.MongoURI)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		log.Fatalf("MongoDB connect: %v", err)
	}
	defer client.Disconnect(ctx)
	if err := client.Ping(ctx, nil); err != nil {
		log.Fatalf("MongoDB ping: %v", err)
	}
	log.Printf("Connected to MongoDB: %s", cfg.MongoDB)

	db := client.Database(cfg.MongoDB)
	users      := db.Collection("users")
	cleanCol   := db.Collection("vehicle_cleanliness_reports")
	crowdCol   := db.Collection("vehicle_crowding_reports")
	delayCol   := db.Collection("vehicle_delay_reports")
	reportsCol := db.Collection("reports")

	hash, err := bcrypt.GenerateFromPassword([]byte("Test1234!"), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("bcrypt: %v", err)
	}
	passwordHash := string(hash)

	created, skipped := 0, 0
	for i := 1; i <= *numUsers; i++ {
		email       := fmt.Sprintf("user%02d@soundsync.test", i)
		displayName := fmt.Sprintf("Seed User %02d", i)

		var existing bson.M
		if err := users.FindOne(ctx, bson.M{"email": email}).Decode(&existing); err == nil {
			log.Printf("  skip existing user: %s", email)
			skipped++
			uid, _ := existing["_id"].(primitive.ObjectID)
			seedReports(ctx, rng, uid, cleanCol, crowdCol, delayCol, reportsCol)
			continue
		}

		now := time.Now()
		doc := bson.M{
			"_id":                  primitive.NewObjectID(),
			"email":                email,
			"passwordHash":         passwordHash,
			"displayName":          displayName,
			"notificationsEnabled": true,
			"tempUnit":             "F",
			"distanceUnit":         "mi",
			"deleted":              false,
			"createdAt":            now,
			"updatedAt":            now,
		}
		res, err := users.InsertOne(ctx, doc)
		if err != nil {
			log.Printf("  ERROR inserting %s: %v", email, err)
			continue
		}
		uid := res.InsertedID.(primitive.ObjectID)
		log.Printf("  created user: %s (%s)", email, uid.Hex())
		created++
		seedReports(ctx, rng, uid, cleanCol, crowdCol, delayCol, reportsCol)
	}
	log.Printf("MongoDB done. Created: %d, Skipped: %d", created, skipped)

	// ── PostgreSQL arrivals ──────────────────────────────────────────────────
	dsn := fmt.Sprintf(
		"host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
		cfg.PGHost, cfg.PGPort, cfg.PGDBName, cfg.PGUser, cfg.PGPassword,
	)
	pg, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("PostgreSQL open: %v", err)
	}
	defer pg.Close()
	if err := pg.Ping(); err != nil {
		log.Fatalf("PostgreSQL ping: %v — check PG_HOST/PORT/DBNAME/USER/PASSWORD in .env", err)
	}
	log.Printf("Connected to PostgreSQL: %s/%s", cfg.PGHost, cfg.PGDBName)

	// Ensure table exists
	_, err = pg.Exec(`
		CREATE TABLE IF NOT EXISTS arrivals (
			id               SERIAL PRIMARY KEY,
			stop_id          TEXT,
			route_id         TEXT,
			trip_id          TEXT,
			headsign         TEXT,
			scheduled_arrival BIGINT,
			predicted_arrival BIGINT,
			delay_seconds    INTEGER,
			recorded_at      TIMESTAMP DEFAULT NOW()
		)`)
	if err != nil {
		log.Fatalf("create arrivals table: %v", err)
	}

	// Check if already seeded
	var existingCount int
	pg.QueryRow(`SELECT COUNT(*) FROM arrivals WHERE route_id LIKE '1_%'`).Scan(&existingCount)
	if existingCount > 0 {
		log.Printf("arrivals table already has %d rows — skipping PostgreSQL seed", existingCount)
	} else {
		total := seedArrivals(pg, rng, *numArrivals)
		log.Printf("PostgreSQL done. Inserted %d arrival rows across %d routes.", total, len(obaRouteIDs))
	}
}

// seedArrivals inserts n fake arrival rows per route into the arrivals table.
func seedArrivals(pg *sql.DB, rng *rand.Rand, n int) int {
	stmt, err := pg.Prepare(`
		INSERT INTO arrivals (stop_id, route_id, trip_id, headsign, scheduled_arrival, predicted_arrival, delay_seconds)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`)
	if err != nil {
		log.Fatalf("prepare arrivals insert: %v", err)
	}
	defer stmt.Close()

	total := 0
	for _, routeID := range obaRouteIDs {
		for i := range n {
			stopID   := stopIDs[rng.Intn(len(stopIDs))]
			headsign := headsigns[rng.Intn(len(headsigns))]
			tripID   := fmt.Sprintf("trip_%s_%d", routeID, i)

			// Random scheduled arrival in last 30 days (Unix ms)
			offsetSec    := rng.Int63n(30 * 24 * 3600)
			scheduledMs  := time.Now().Add(-time.Duration(offsetSec)*time.Second).UnixMilli()

			// Delay: mostly small, occasionally large — realistic distribution
			delaySec := randomDelay(rng)
			predictedMs := scheduledMs + int64(delaySec)*1000

			if _, err := stmt.Exec(stopID, routeID, tripID, headsign, scheduledMs, predictedMs, delaySec); err != nil {
				log.Printf("  arrivals insert error: %v", err)
				continue
			}
			total++
		}
	}
	return total
}

// randomDelay returns a realistic delay in seconds.
// 70% of the time within ±120s (on-time), rest up to ±600s.
func randomDelay(rng *rand.Rand) int {
	if rng.Float64() < 0.70 {
		return rng.Intn(241) - 120 // -120 to +120
	}
	sign := 1
	if rng.Float64() < 0.3 {
		sign = -1
	}
	return sign * (120 + rng.Intn(481)) // ±120 to ±600
}

// seedReports inserts vehicle and generic reports for a user if none exist yet.
func seedReports(
	ctx context.Context,
	rng *rand.Rand,
	userID primitive.ObjectID,
	cleanCol, crowdCol, delayCol, reportsCol *mongo.Collection,
) {
	count, _ := cleanCol.CountDocuments(ctx, bson.M{"userId": userID})
	if count == 0 {
		n := 3 + rng.Intn(6)
		for range n {
			insertVehicleReport(ctx, rng, userID, cleanCol, crowdCol, delayCol)
		}
		log.Printf("    inserted %d vehicle reports", n)
	}

	count, _ = reportsCol.CountDocuments(ctx, bson.M{"userId": userID})
	if count == 0 {
		n := 1 + rng.Intn(3)
		for range n {
			insertReport(ctx, rng, userID, reportsCol)
		}
		log.Printf("    inserted %d generic reports", n)
	}
}

func insertVehicleReport(
	ctx context.Context,
	rng *rand.Rand,
	userID primitive.ObjectID,
	cleanCol, crowdCol, delayCol *mongo.Collection,
) {
	doc := bson.M{
		"_id":       primitive.NewObjectID(),
		"userId":    userID,
		"vehicleId": vehicleIDs[rng.Intn(len(vehicleIDs))],
		"routeId":   routeIDs[rng.Intn(len(routeIDs))],
		"level":     1 + rng.Intn(5),
		"createdAt": randomPastTime(rng, 30),
	}
	cols := []*mongo.Collection{cleanCol, crowdCol, delayCol}
	if _, err := cols[rng.Intn(3)].InsertOne(ctx, doc); err != nil {
		log.Printf("    vehicle report insert error: %v", err)
	}
}

func insertReport(
	ctx context.Context,
	rng *rand.Rand,
	userID primitive.ObjectID,
	reportsCol *mongo.Collection,
) {
	doc := bson.M{
		"_id":         primitive.NewObjectID(),
		"userId":      userID,
		"routeId":     routeIDs[rng.Intn(len(routeIDs))],
		"vehicleId":   vehicleIDs[rng.Intn(len(vehicleIDs))],
		"type":        reportTypes[rng.Intn(len(reportTypes))],
		"severity":    reportSeverities[rng.Intn(len(reportSeverities))],
		"description": reportDescriptions[rng.Intn(len(reportDescriptions))],
		"createdAt":   randomPastTime(rng, 30),
	}
	if _, err := reportsCol.InsertOne(ctx, doc); err != nil {
		log.Printf("    report insert error: %v", err)
	}
}

func randomPastTime(rng *rand.Rand, days int) time.Time {
	maxSec := int64(days * 24 * 3600)
	return time.Now().Add(-time.Duration(rng.Int63n(maxSec)) * time.Second)
}
