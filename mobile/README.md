# SoundSync Mobile

Flutter app for the SoundSyncAI transit tracker — real-time Sound Transit bus and rail tracking for the Seattle area.

---

## Prerequisites

- Flutter 3.17+ (project uses SDK `>=3.3.0`)
- Android Studio with an Android emulator configured, **or** a physical Android device
- The Go API running on `localhost:8080` (see `api/`)
- MongoDB running via Docker (see root `docker-compose.yml`)

---

## Setup

### 1. Install dependencies

```bash
cd mobile
flutter pub get
```

### 2. Create your API key file

The app requires a Google Maps API key for map display, Places autocomplete, and Directions. The key is **never committed** — you create the file locally.

Create `mobile/dart_defines.env`:

```
GOOGLE_MAPS_MOBILE_KEY=your_google_maps_api_key_here
```

This file is gitignored. Ask a team member for the key or create one in [Google Cloud Console](https://console.cloud.google.com/apis/credentials) with these APIs enabled:
- Maps SDK for Android
- Places API
- Directions API

---

## Running the App

### Option A — VS Code (recommended)

Press **F5** or go to **Run → Start Debugging** and select `SoundSync Mobile (debug)`.

The VS Code launch config (`.vscode/launch.json`) automatically passes `--dart-define-from-file=dart_defines.env` so the API key is injected at build time.

### Option B — Terminal

```bash
cd mobile
flutter run --dart-define-from-file=dart_defines.env
```

> If you run `flutter run` without `--dart-define-from-file`, the Maps key will be empty and the map, search, and directions features will return `REQUEST_DENIED` errors.

---

## Running on an Emulator

### Start the emulator

From Android Studio → **Device Manager** → click **▶** next to your device.

Or from the terminal:

```bash
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_6_API_33
```

### Set the GPS location

The emulator defaults to a location that may be far from Seattle. Fix it:

**Option 1 — Extended Controls (easiest)**
1. Click the **⋮ three-dot menu** on the emulator's side toolbar
2. Click **Location**
3. Search for an address or enter coordinates directly:
   - **Latitude:** `47.6062`
   - **Longitude:** `-122.3321`
4. Click **Set Location**

**Option 2 — Terminal**
```bash
# Order is: longitude first, then latitude
adb -s emulator-5554 emu geo fix -122.3321 47.6062
```

**Option 3 — Simulate movement**

In Extended Controls → **Location → Routes** tab, search a route and hit **Play Route** to move the emulator along a path over time.

### If the app still shows the wrong location

1. On the emulator go to **Settings → Location** and make sure it is **On**
2. Set mode to **High accuracy**
3. Hot restart the app with `R` in the terminal

---

## Useful Commands

| Goal | Command |
|---|---|
| Run with key (debug) | `flutter run --dart-define-from-file=dart_defines.env` |
| Run in release mode | `flutter run --release --dart-define-from-file=dart_defines.env` |
| List connected devices | `flutter devices` |
| Run on specific device | `flutter run -d emulator-5554 --dart-define-from-file=dart_defines.env` |
| Hot reload (while running) | Press `r` in terminal |
| Hot restart (while running) | Press `R` in terminal |
| Quit | Press `q` in terminal |

---

## Make sure the API is running

The mobile app connects to `http://10.0.2.2:8080` on Android emulator (`10.0.2.2` is how the emulator reaches your machine's `localhost`). Start the backend before running the app:

```bash
cd api
go run main.go
```
