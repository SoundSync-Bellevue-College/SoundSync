# users

| Field | Type | Notes |
|-------|------|-------|
| `_id` | ObjectId | Auto-generated |
| `email` | string | Unique index, required |
| `passwordHash` | string | bcrypt, never returned to client |
| `displayName` | string | Required |
| `createdAt` | Date | Set on insert |
| `updatedAt` | Date | Set on insert + update |
