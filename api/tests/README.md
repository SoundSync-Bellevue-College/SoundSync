# API Integration Tests

## Overview

These are integration tests for the SoundSyncAI Go API. They test real HTTP endpoints against a live MongoDB instance using a dedicated `soundsync_test` database that is automatically created and dropped each run.

---

## Prerequisites

- Go 1.22+
- Docker Desktop running
- MongoDB container up (comes with the project's `docker-compose.yml`)

---

## Step 1 — Open a terminal in the right folder

```bash
cd "C:\windowFiles\wayne_personal\School\Bellevue College\CS 481 Capstone 1\SoundSyncAI\SoundSyncWS\api"
```

---

## Step 2 — Make sure MongoDB is running

```bash
docker compose -f ../docker-compose.yml ps
```

You should see `soundsync_mongo` with status `Up`. If it is not running:

```bash
docker compose -f ../docker-compose.yml up -d mongo
```

---

## Step 3 — Run all tests

```bash
go test ./tests/... -v
```

**What each part means:**
- `go test` — Go's built-in test runner
- `./tests/...` — run every test file inside the `tests/` folder
- `-v` — verbose: print each test name and whether it passed or failed

Expected output:

```
=== RUN   TestHealth
--- PASS: TestHealth (0.01s)
=== RUN   TestRegister_Success
--- PASS: TestRegister_Success (0.18s)
=== RUN   TestRegister_DuplicateEmail
--- PASS: TestRegister_DuplicateEmail (0.14s)
...
PASS
ok      soundsync/api/tests     4.23s
```

A line starting with `--- PASS` means the test passed. `--- FAIL` means it failed and will show you why.

---

## Step 4 — Run just one test

When debugging a specific feature, run only that test:

```bash
go test ./tests/... -v -run TestLogin_Success
```

`-run` accepts a name or a prefix — to run all login tests at once:

```bash
go test ./tests/... -v -run TestLogin
```

This matches `TestLogin_Success`, `TestLogin_WrongPassword`, and `TestLogin_UnknownEmail`.

Same works for any group:

```bash
go test ./tests/... -v -run TestVehicleReport
go test ./tests/... -v -run TestFavorites
go test ./tests/... -v -run TestRegister
```

---

## Step 5 — Reading a failure

If a test fails it looks like this:

```
=== RUN   TestLogin_WrongPassword
    handlers_test.go:163: expected 401, got 200
--- FAIL: TestLogin_WrongPassword (0.09s)
FAIL
```

It tells you:
- **Which test** failed (`TestLogin_WrongPassword`)
- **Which line** in the file triggered the failure (`handlers_test.go:163`)
- **What went wrong** (`expected 401, got 200`)

---

## Quick Reference

| Goal | Command |
|---|---|
| Run all tests | `go test ./tests/... -v` |
| Run one test | `go test ./tests/... -v -run TestHealth` |
| Run a group | `go test ./tests/... -v -run TestVehicleReport` |
| Run silently (just pass/fail summary) | `go test ./tests/...` |
| Set a time limit | `go test ./tests/... -v -timeout 60s` |

---

## What is tested

| Group | Tests |
|---|---|
| Health | Server reachability |
| Register | Success, missing fields, duplicate email, short password |
| Login | Success, wrong password, unknown email |
| Get Me | Authenticated, no token, invalid token |
| Settings | Update temp/distance unit, invalid unit, empty patch |
| Delete Account | Soft-delete then login fails |
| Favorites | Create, list, delete, verify empty |
| Reports | Create (auth + unauth), get by routeId, missing routeId |
| Vehicle Reports | Cleanliness, crowding, delay, invalid level, unauthenticated |
| Vehicle Reports List/Delete | Full lifecycle, wrong-owner rejected, invalid ID |

---

## Notes

- The test suite uses a dedicated `soundsync_test` database. Your real `soundsync` database is never touched.
- The database is dropped automatically when the suite finishes.
- If MongoDB is unreachable the suite skips gracefully instead of failing.
- To use a different MongoDB URI, set the `MONGO_URI` environment variable before running:

```bash
MONGO_URI=mongodb://root:rootpassword@localhost:27017 go test ./tests/... -v
```
