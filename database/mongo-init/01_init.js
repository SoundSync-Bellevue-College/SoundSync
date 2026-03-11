// MongoDB initialization script — runs once on first container boot.
// Creates the application user and sets up indexes for the soundsync database.

db = db.getSiblingDB('soundsync');

// Create application user with read/write access
db.createUser({
  user: 'soundsync_app',
  pwd: 'apppassword',
  roles: [{ role: 'readWrite', db: 'soundsync' }],
});

// ─── users collection ───────────────────────────────────────────────────────
db.createCollection('users');
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ createdAt: 1 });

// ─── favorite_routes collection ──────────────────────────────────────────────
db.createCollection('favorite_routes');
db.favorite_routes.createIndex({ userId: 1 });
db.favorite_routes.createIndex({ userId: 1, createdAt: -1 });
db.favorite_routes.createIndex({ transitRouteIds: 1 });

// ─── reports collection ──────────────────────────────────────────────────────
db.createCollection('reports');
db.reports.createIndex({ routeId: 1 });
db.reports.createIndex({ userId: 1 });
db.reports.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // TTL: 30 days

// ─── vehicle_cleanliness_reports collection ───────────────────────────────────
db.createCollection('vehicle_cleanliness_reports');
db.vehicle_cleanliness_reports.createIndex({ vehicleId: 1, createdAt: -1 });
db.vehicle_cleanliness_reports.createIndex({ userId: 1 });
db.vehicle_cleanliness_reports.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // TTL: 30 days

// ─── vehicle_crowding_reports collection ──────────────────────────────────────
db.createCollection('vehicle_crowding_reports');
db.vehicle_crowding_reports.createIndex({ vehicleId: 1, createdAt: -1 });
db.vehicle_crowding_reports.createIndex({ userId: 1 });
db.vehicle_crowding_reports.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // TTL: 30 days

// ─── vehicle_delay_reports collection ────────────────────────────────────────
db.createCollection('vehicle_delay_reports');
db.vehicle_delay_reports.createIndex({ vehicleId: 1, createdAt: -1 });
db.vehicle_delay_reports.createIndex({ userId: 1 });
db.vehicle_delay_reports.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // TTL: 30 days

// ─── notifications collection ─────────────────────────────────────────────────
db.createCollection('notifications');
db.notifications.createIndex({ userId: 1, read: 1, createdAt: -1 });
db.notifications.createIndex({ createdAt: 1 }, { expireAfterSeconds: 604800 }); // TTL: 7 days

print('SoundSync DB initialized successfully.');
