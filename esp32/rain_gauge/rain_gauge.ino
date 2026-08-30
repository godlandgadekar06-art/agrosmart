/*
  AgroSmart — Smart Automatic Rain Gauge (ESP32)
  ------------------------------------------------
  Reads a tipping-bucket rain sensor (or analog rain sensor — see note below),
  calculates rainfall in mm, and POSTs the reading to a Supabase Edge Function
  every REPORT_INTERVAL_MS milliseconds.

  Hardware assumed:
  - ESP32 dev board
  - Tipping bucket rain gauge sensor connected to a digital GPIO (interrupt pin)
    Each "tip" = a fixed volume of water, typically 0.2794mm per tip for
    standard tipping buckets — CHANGE THIS to match your sensor's datasheet.
  - Optional: battery voltage divider on an ADC pin to report battery level.

  Security model:
  - The device NEVER holds a broad Supabase API key. It holds only a
    per-device secret (DEVICE_KEY) that Supabase Auth cannot forge.
  - It posts to a Supabase Edge Function ("ingest-rainfall"), which validates
    DEVICE_CODE + DEVICE_KEY against the rain_gauge_devices table server-side,
    then inserts the row using the service role key (which never leaves the
    server). This keeps the ESP32 unable to read/write anything except its
    own readings, even if the device is physically stolen.
    See /supabase/functions/ingest-rainfall for that function's code.
*/

#include <WiFi.h>
#include <HTTPClient.h>

// ---------- CONFIG: EDIT THESE ----------
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Your Supabase project's Edge Function URL, e.g.:
// https://xxxxxxxx.supabase.co/functions/v1/ingest-rainfall
const char* INGEST_URL = "https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-rainfall";

const char* DEVICE_CODE = "AGS-RG-0001";   // matches rain_gauge_devices.device_code
const char* DEVICE_KEY  = "REPLACE_WITH_DEVICE_SECRET"; // matches rain_gauge_devices.device_key

const float MM_PER_TIP = 0.2794;           // calibrate to your bucket's datasheet
const int   RAIN_SENSOR_PIN = 27;          // interrupt-capable GPIO
const int   BATTERY_ADC_PIN = 34;          // optional voltage divider input

const unsigned long REPORT_INTERVAL_MS = 5UL * 60UL * 1000UL; // report every 5 min
// -----------------------------------------

volatile unsigned long tipCount = 0;
unsigned long lastReportTime = 0;

void IRAM_ATTR onTip() {
  tipCount++;
}

void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 20000) {
    delay(500);
    Serial.print(".");
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected. IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nWiFi connection FAILED — will retry next cycle.");
  }
}

float readBatteryVoltage() {
  int raw = analogRead(BATTERY_ADC_PIN);
  // Adjust this formula to match your specific voltage divider resistors.
  float voltage = (raw / 4095.0) * 3.3 * 2.0;
  return voltage;
}

void sendReading(float rainfallMm, float batteryVoltage) {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
    if (WiFi.status() != WL_CONNECTED) return;
  }

  HTTPClient http;
  http.begin(INGEST_URL);
  http.addHeader("Content-Type", "application/json");

  String payload = String("{") +
    "\"device_code\":\"" + DEVICE_CODE + "\"," +
    "\"device_key\":\"" + DEVICE_KEY + "\"," +
    "\"rainfall_mm\":" + String(rainfallMm, 3) + "," +
    "\"battery_voltage\":" + String(batteryVoltage, 2) +
  "}";

  int httpCode = http.POST(payload);
  Serial.print("POST response: ");
  Serial.println(httpCode);
  if (httpCode != 200 && httpCode != 201) {
    Serial.println("Response body: " + http.getString());
  }
  http.end();
}

void setup() {
  Serial.begin(115200);
  pinMode(RAIN_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(RAIN_SENSOR_PIN), onTip, FALLING);

  connectWiFi();
  lastReportTime = millis();
}

void loop() {
  unsigned long now = millis();

  if (now - lastReportTime >= REPORT_INTERVAL_MS) {
    noInterrupts();
    unsigned long tips = tipCount;
    tipCount = 0;
    interrupts();

    float rainfallMm = tips * MM_PER_TIP;
    float battery = readBatteryVoltage();

    Serial.printf("Reporting: %.3f mm rain, %.2f V battery\n", rainfallMm, battery);

    // Only send if there's something meaningful to report, or every cycle
    // if you want a "device is alive" heartbeat even at 0mm — recommended,
    // since it lets the app show "last seen" accurately.
    sendReading(rainfallMm, battery);

    lastReportTime = now;
  }

  delay(100); // keep loop light so interrupts stay responsive
}
