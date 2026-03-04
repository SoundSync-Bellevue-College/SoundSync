package auth

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type RouteSubscription struct {
	RouteID string `json:"routeId" bson:"routeId"`
}

type NotificationSettings struct {
	Enabled       bool                `json:"enabled" bson:"enabled"`
	Subscriptions []RouteSubscription `json:"subscriptions" bson:"subscriptions"`
}

type User struct {
	ID            primitive.ObjectID   `json:"-" bson:"_id,omitempty"`
	Username      string               `json:"username" bson:"username"`
	Name          string               `json:"name" bson:"name,omitempty"`
	Email         string               `json:"email" bson:"email,omitempty"`
	Password      string               `json:"-" bson:"password,omitempty"`
	PasswordHash  string               `json:"-" bson:"password_hash,omitempty"`
	CreatedDate   any                  `json:"createdDate" bson:"createdDate"`
	Notifications NotificationSettings `json:"notifications" bson:"notifications"`
}

type UserResponse struct {
	ID            string               `json:"id"`
	Username      string               `json:"username"`
	Name          string               `json:"name,omitempty"`
	Email         string               `json:"email,omitempty"`
	CreatedDate   time.Time            `json:"createdDate"`
	Notifications NotificationSettings `json:"notifications"`
}

type revokedToken struct {
	JTI       string    `bson:"jti"`
	ExpiresAt time.Time `bson:"expires_at"`
	CreatedAt time.Time `bson:"created_at"`
}

type Claims struct {
	UserID   string `json:"uid"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

type Service struct {
	usersColl   *mongo.Collection
	revokedColl *mongo.Collection
	jwtSecret   []byte
	tokenTTL    time.Duration
}

func NewService(database *mongo.Database, jwtSecret string, tokenTTL time.Duration) (*Service, error) {
	s := &Service{
		usersColl:   database.Collection("users"),
		revokedColl: database.Collection("revoked_tokens"),
		jwtSecret:   []byte(jwtSecret),
		tokenTTL:    tokenTTL,
	}
	if err := s.ensureIndexes(context.Background()); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Service) Signup(username, name, email, password string) (UserResponse, error) {
	username = strings.TrimSpace(strings.ToLower(username))
	name = strings.TrimSpace(name)
	email = strings.TrimSpace(strings.ToLower(email))
	if username == "" || name == "" || email == "" || password == "" {
		return UserResponse{}, errors.New("username, name, email, and password are required")
	}

	now := time.Now().UTC()
	user := User{
		Username:      username,
		Name:          name,
		Email:         email,
		Password:      password,
		CreatedDate:   now,
		Notifications: NotificationSettings{Enabled: true, Subscriptions: []RouteSubscription{}},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := s.usersColl.InsertOne(ctx, user)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return UserResponse{}, errors.New("user already exists")
		}
		return UserResponse{}, err
	}

	id, ok := result.InsertedID.(primitive.ObjectID)
	if !ok {
		return UserResponse{}, errors.New("failed to create user")
	}
	user.ID = id

	return toUserResponse(user), nil
}

func (s *Service) Login(loginID, password string) (token string, user UserResponse, err error) {
	loginID = strings.TrimSpace(strings.ToLower(loginID))
	if loginID == "" || password == "" {
		return "", UserResponse{}, errors.New("username/email and password are required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var dbUser User
	err = s.usersColl.FindOne(ctx, bson.M{
		"$or": []bson.M{
			{"username": loginID},
			{"email": loginID},
		},
	}).Decode(&dbUser)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return "", UserResponse{}, errors.New("invalid credentials")
		}
		return "", UserResponse{}, err
	}

	if !passwordMatches(dbUser, password) {
		return "", UserResponse{}, errors.New("invalid credentials")
	}

	token, err = s.newToken(dbUser)
	if err != nil {
		return "", UserResponse{}, err
	}
	return token, toUserResponse(dbUser), nil
}

func (s *Service) Logout(token string) error {
	claims, err := s.parseToken(token)
	if err != nil {
		return err
	}
	if claims.ID == "" || claims.ExpiresAt == nil {
		return errors.New("invalid token")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = s.revokedColl.InsertOne(ctx, revokedToken{JTI: claims.ID, ExpiresAt: claims.ExpiresAt.Time, CreatedAt: time.Now().UTC()})
	if err != nil && !mongo.IsDuplicateKeyError(err) {
		return err
	}
	return nil
}

func (s *Service) UserIDFromToken(token string) (string, bool) {
	claims, err := s.parseToken(token)
	if err != nil {
		return "", false
	}
	if s.isRevoked(claims.ID) {
		return "", false
	}
	return claims.UserID, true
}

func (s *Service) ensureIndexes(ctx context.Context) error {
	_, err := s.usersColl.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "username", Value: 1}}, Options: options.Index().SetUnique(true).SetSparse(true)},
		{Keys: bson.D{{Key: "email", Value: 1}}, Options: options.Index().SetUnique(true).SetSparse(true)},
		{Keys: bson.D{{Key: "notifications.enabled", Value: 1}}},
	})
	if err != nil {
		return err
	}

	_, err = s.revokedColl.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "jti", Value: 1}}, Options: options.Index().SetUnique(true)},
		{Keys: bson.D{{Key: "expires_at", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0)},
	})
	return err
}

func (s *Service) isRevoked(jti string) bool {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	count, err := s.revokedColl.CountDocuments(ctx, bson.M{"jti": jti})
	if err != nil {
		return true
	}
	return count > 0
}

func (s *Service) newToken(user User) (string, error) {
	now := time.Now().UTC()
	claims := Claims{
		UserID:   user.ID.Hex(),
		Username: user.Username,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        newID("jti"),
			Subject:   user.ID.Hex(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.tokenTTL)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

func (s *Service) parseToken(token string) (*Claims, error) {
	parsed, err := jwt.ParseWithClaims(token, &Claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return s.jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := parsed.Claims.(*Claims)
	if !ok || !parsed.Valid {
		return nil, errors.New("invalid token")
	}
	if claims.UserID == "" || claims.ID == "" {
		return nil, errors.New("invalid token")
	}
	return claims, nil
}

func passwordMatches(user User, password string) bool {
	return user.Password != "" && user.Password == password
}

func toUserResponse(user User) UserResponse {
	return UserResponse{
		ID:            user.ID.Hex(),
		Username:      user.Username,
		Name:          user.Name,
		Email:         user.Email,
		CreatedDate:   normalizeCreatedDate(user.CreatedDate),
		Notifications: user.Notifications,
	}
}

func normalizeCreatedDate(value any) time.Time {
	switch v := value.(type) {
	case time.Time:
		return v.UTC()
	case primitive.DateTime:
		return v.Time().UTC()
	case string:
		t, err := time.Parse(time.RFC3339, v)
		if err == nil {
			return t.UTC()
		}
	}
	return time.Time{}
}

func newID(prefix string) string {
	buf := make([]byte, 16)
	_, _ = rand.Read(buf)
	return prefix + "_" + hex.EncodeToString(buf)
}
