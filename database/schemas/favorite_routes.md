# favorite_routes

| Field | Type | Notes |
|-------|------|-------|
| `_id` | ObjectId | Auto-generated |
| `userId` | ObjectId | Indexed, references users._id |
| `label` | string | User-defined name, e.g. "Home → Work" |
| `origin` | object | `{ name: string, lat: number, lng: number }` |
| `destination` | object | `{ name: string, lat: number, lng: number }` |
| `transitRouteIds` | string[] | Sound Transit route IDs |
| `createdAt` | Date | Set on insert |
