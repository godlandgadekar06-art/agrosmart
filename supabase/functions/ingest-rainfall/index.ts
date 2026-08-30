// Supabase Edge Function: ingest-rainfall
// Deploy with: supabase functions deploy ingest-rainfall
//
// Purpose: lets the ESP32 rain gauge submit readings WITHOUT ever holding
// a Supabase API key that could read/write other tables. The device only
// knows its own device_code + device_key. This function verifies those
// against rain_gauge_devices, then inserts using the service role key
// (kept server-side as an environment secret, never sent to the device).

import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json();
    const { device_code, device_key, rainfall_mm, battery_voltage } = body;

    if (!device_code || !device_key || rainfall_mm === undefined) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Look up the device and verify its secret key matches
    const { data: device, error: deviceError } = await supabase
      .from("rain_gauge_devices")
      .select("id, device_key")
      .eq("device_code", device_code)
      .single();

    if (deviceError || !device) {
      return new Response(JSON.stringify({ error: "Unknown device" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (device.device_key !== device_key) {
      return new Response(JSON.stringify({ error: "Invalid device key" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Insert the reading
    const { error: insertError } = await supabase
      .from("rainfall_readings")
      .insert({
        device_id: device.id,
        rainfall_mm,
        battery_voltage: battery_voltage ?? null,
      });

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Update last_seen_at on the device
    await supabase
      .from("rain_gauge_devices")
      .update({ last_seen_at: new Date().toISOString() })
      .eq("id", device.id);

    return new Response(JSON.stringify({ success: true }), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
