# AgroSmart

A mobile app for Indian farmers combining real-time rainfall data (from a
custom ESP32 rain gauge), weather forecasts, and rule-based crop/irrigation
recommendations — built simple, bilingual (Marathi/English), and Android-first.

## Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Android-first) |
| Backend / database | Supabase (Postgres, Auth, Realtime, Storage, Edge Functions) |
| Hardware | ESP32 + tipping-bucket rain sensor |
| Hosting for app code | GitHub (+ GitHub Actions for CI, optional) |
| Push notifications | Firebase Cloud Messaging |

## Repo structure

```
agrosmart/
├── lib/
│   ├── main.dart                    # App entry, Supabase init, auth routing
│   ├── theme.dart                   # Colors, fonts, button/card styles
│   ├── l10n/app_strings.dart        # Marathi + English translations
│   ├── services/supabase_service.dart  # All backend calls in one place
│   ├── screens/                     # Login, profile setup, dashboard, etc.
│   └── widgets/                     # Feature cards, voice assistant button
├── supabase/
│   ├── schema.sql                   # Full DB schema, RLS policies, seed data
│   └── functions/ingest-rainfall/   # Edge Function the ESP32 posts to
├── esp32/rain_gauge/rain_gauge.ino  # Arduino sketch for the rain gauge
└── pubspec.yaml
```

## Setup — step by step

### 1. Supabase project
1. Create a free project at supabase.com.
2. Open **SQL Editor** → paste and run `supabase/schema.sql`. This creates
   all tables, RLS policies, and a few seed crops for testing.
3. Under **Authentication → Providers**, enable **Phone** auth (requires an
   SMS provider like Twilio or MSG91 — Supabase's docs walk through linking
   one; this matters for rural users who may not have email).
4. Under **Settings → API**, copy your **Project URL** and **anon public
   key** into `lib/main.dart` (`supabaseUrl`, `supabaseAnonKey`).
5. Deploy the ingest function:
   ```bash
   supabase functions deploy ingest-rainfall
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

### 2. Register a rain gauge device
In the Supabase Table Editor, add a row to `rain_gauge_devices` with a
`device_code` (e.g. `AGS-RG-0001`) and a random `device_key` (any long
random string — this is the device's password). Later, link
`owner_farmer_id` to a real farmer once one signs up.

### 3. ESP32 firmware
1. Open `esp32/rain_gauge/rain_gauge.ino` in Arduino IDE (or PlatformIO).
2. Install the ESP32 board package and the `HTTPClient`/`WiFi` libraries
   (bundled with the ESP32 core).
3. Edit the CONFIG section at the top: Wi-Fi credentials, your Edge
   Function URL, and the `device_code`/`device_key` matching what you
   registered in step 2.
4. Calibrate `MM_PER_TIP` to your specific tipping-bucket sensor's
   datasheet value.
5. Flash to the ESP32. It will report rainfall every 5 minutes by default.

### 4. Flutter app
```bash
flutter pub get
flutter run          # test on a connected Android device/emulator
flutter build apk    # produce a release APK
```

### 5. Push notifications (optional but recommended for alerts)
1. Create a Firebase project, add an Android app, download
   `google-services.json` into `android/app/`.
2. Follow the `firebase_messaging` package's Android setup steps (adds a
   Gradle plugin) — see pub.dev/packages/firebase_messaging.
3. Alerts can be triggered from a Supabase Edge Function (e.g. a scheduled
   function checking rainfall thresholds) that calls the FCM API.

### 6. GitHub
1. Push this repo to GitHub as usual.
2. Optional: add a GitHub Actions workflow to auto-build the APK on every
   push (ask me for a `flutter-build.yml` workflow if you want this set up).
3. GitHub does not host or run any part of the live app — it only stores
   and version-controls the code. Supabase is the entire backend.

## What's scaffolded vs. what's next

**Already built:**
- Phone OTP auth + farmer profile setup
- Dashboard with live rainfall card + feature grid
- Rainfall history chart (30-day line chart)
- Rule-based crop recommendation screen (season + rainfall matching)
- Alerts/notifications screen
- Marathi/English translation system
- Voice assistant button (speech-to-text + text-to-speech scaffolding)
- Full Supabase schema with RLS security
- ESP32 firmware + secure ingest Edge Function

**Still to build out** (structure is ready, screens are stubs):
- Weather forecast screen (needs an external weather API — IMD or
  OpenWeatherMap — wired into `SupabaseService` or called directly)
- Irrigation advice detail screen (uses `crop_recommendation_rules` table)
- Crop disease detail screens (uses `crop_diseases` table)
- Fertilizer recommendation detail screens
- Seed/fertilizer booking form (table + service methods already exist)
- Insurance scheme listing screen (table + service method already exist)
- Voice command routing (STT captures text; routing that text to actions
  is a small keyword-matching layer you can add in each screen)
- App icon, splash screen, and Play Store listing assets

Every "still to build" item already has its Supabase table and service
method ready — they're UI-only work from here.
