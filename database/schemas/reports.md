# reports

| Field | Type | Notes |
|-------|------|-------|
| `_id` | ObjectId | Auto-generated |
| `userId` | ObjectId | References users._id |
| `routeId` | string | Indexed, Sound Transit route ID |
| `vehicleId` | string | Optional, Sound Transit vehicle ID |
| `type` | string | Enum: `delay`, `cleanliness`, `crowding`, `other` |
| `severity` | string | Enum: `low`, `medium`, `high` |
| `description` | string | Optional free-text |
| `location` | object | `{ lat: number, lng: number }` |
| `createdAt` | Date | TTL index — documents expire after 30 days |
