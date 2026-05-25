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

// ─── team_members collection ──────────────────────────────────────────────────
db.createCollection('team_members');
db.team_members.createIndex({ sort_order: 1 });
db.team_members.insertMany([
  {
    name: 'Abshira', pronouns: 'she/her', role: 'UI Front End & Mobile',
    photo_url: 'https://soundsync.live/team/abshira.jpg',
    quote: 'Add your personal quote here.',
    linkedin: 'https://www.linkedin.com/in/abshira-salat-ba1829260/',
    github: 'https://github.com/AbshiraSalat', sort_order: 1,
  },
  {
    name: 'Tony', pronouns: 'he/him', role: 'System DevOps, Auth & Security',
    photo_url: 'https://soundsync.live/team/tony.jpg',
    quote: 'Add your personal quote here.',
    linkedin: 'https://www.linkedin.com/in/anye-che-b59624202/',
    github: 'https://github.com/cheTonyA', sort_order: 2,
  },
  {
    name: 'Nolan', pronouns: 'he/him', role: 'Performance Metrics & AI Prediction',
    photo_url: 'https://soundsync.live/team/nolan.jpg',
    quote: 'Add your personal quote here.',
    linkedin: 'https://www.linkedin.com/in/nolan-ngo-2b3304203/',
    github: 'https://github.com/nolngo', sort_order: 3,
  },
  {
    name: 'Wayne', pronouns: 'he/him', role: 'Backend, Testing & API Management',
    photo_url: 'https://soundsync.live/team/wayne.jpg',
    quote: 'Add your personal quote here.',
    linkedin: 'https://www.linkedin.com/in/thu-san/',
    github: 'https://github.com/waynesan41', sort_order: 4,
  },
]);

print('SoundSync DB initialized successfully.');
