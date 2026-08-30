-- ============================================================
-- AgroSmart — Supabase Schema
-- Run this in Supabase SQL Editor (Project > SQL Editor > New query)
-- ============================================================

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. FARMERS
-- ------------------------------------------------------------
create table if not exists farmers (
  id uuid primary key default uuid_generate_v4(),
  auth_id uuid unique references auth.users(id) on delete cascade,
  name text not null,
  phone text unique not null,
  village text,
  taluka text,
  district text,
  state text default 'Maharashtra',
  preferred_language text default 'mr' check (preferred_language in ('mr','en')),
  farm_size_acres numeric,
  soil_type text,
  created_at timestamptz default now()
);

alter table farmers enable row level security;

create policy "Farmers can view own profile"
  on farmers for select
  using (auth.uid() = auth_id);

create policy "Farmers can update own profile"
  on farmers for update
  using (auth.uid() = auth_id);

create policy "Farmers can insert own profile"
  on farmers for insert
  with check (auth.uid() = auth_id);

-- ------------------------------------------------------------
-- 2. RAIN GAUGE DEVICES
-- ------------------------------------------------------------
create table if not exists rain_gauge_devices (
  id uuid primary key default uuid_generate_v4(),
  device_code text unique not null,       -- e.g. "AGS-RG-0001", flashed into the ESP32
  device_key text unique not null,        -- secret key the ESP32 sends to authenticate inserts
  owner_farmer_id uuid references farmers(id) on delete set null,
  village text,
  latitude numeric,
  longitude numeric,
  last_seen_at timestamptz,
  created_at timestamptz default now()
);

alter table rain_gauge_devices enable row level security;

create policy "Farmers can view devices in their village or their own"
  on rain_gauge_devices for select
  using (
    owner_farmer_id in (select id from farmers where auth_id = auth.uid())
    or village in (select village from farmers where auth_id = auth.uid())
  );

-- ------------------------------------------------------------
-- 3. RAINFALL READINGS (time-series data from ESP32)
-- ------------------------------------------------------------
create table if not exists rainfall_readings (
  id bigint generated always as identity primary key,
  device_id uuid references rain_gauge_devices(id) on delete cascade,
  rainfall_mm numeric not null,
  battery_voltage numeric,
  recorded_at timestamptz default now()
);

create index if not exists idx_rainfall_device_time
  on rainfall_readings (device_id, recorded_at desc);

alter table rainfall_readings enable row level security;

create policy "Farmers can view readings for devices they can see"
  on rainfall_readings for select
  using (
    device_id in (
      select id from rain_gauge_devices
      where owner_farmer_id in (select id from farmers where auth_id = auth.uid())
         or village in (select village from farmers where auth_id = auth.uid())
    )
  );

-- Insert policy: the ESP32 uses a restricted service key (see README) that
-- bypasses RLS via a dedicated "device insert" Edge Function, so no public
-- insert policy is defined here — devices never talk to the DB directly
-- with a broad key. See /esp32/README section "Security model".

-- ------------------------------------------------------------
-- 4. CROPS (reference data, admin-managed)
-- ------------------------------------------------------------
create table if not exists crops (
  id uuid primary key default uuid_generate_v4(),
  name_en text not null,
  name_mr text not null,
  season text not null check (season in ('kharif','rabi','summer')),
  ideal_rainfall_min_mm numeric not null,
  ideal_rainfall_max_mm numeric not null,
  soil_type text,
  growth_duration_days integer,
  icon_key text default 'crop_default'
);

alter table crops enable row level security;
create policy "Anyone can read crops" on crops for select using (true);

-- ------------------------------------------------------------
-- 5. CROP RECOMMENDATION RULES (rule-based engine)
-- ------------------------------------------------------------
create table if not exists crop_recommendation_rules (
  id uuid primary key default uuid_generate_v4(),
  crop_id uuid references crops(id) on delete cascade,
  min_rainfall_mm numeric not null,
  max_rainfall_mm numeric not null,
  season text not null,
  irrigation_advice_en text,
  irrigation_advice_mr text,
  fertilizer_advice_en text,
  fertilizer_advice_mr text
);

alter table crop_recommendation_rules enable row level security;
create policy "Anyone can read recommendation rules"
  on crop_recommendation_rules for select using (true);

-- ------------------------------------------------------------
-- 6. CROP DISEASES (reference content)
-- ------------------------------------------------------------
create table if not exists crop_diseases (
  id uuid primary key default uuid_generate_v4(),
  crop_id uuid references crops(id) on delete cascade,
  name_en text not null,
  name_mr text not null,
  symptoms_en text,
  symptoms_mr text,
  treatment_en text,
  treatment_mr text
);

alter table crop_diseases enable row level security;
create policy "Anyone can read crop diseases"
  on crop_diseases for select using (true);

-- ------------------------------------------------------------
-- 7. INSURANCE SCHEMES (reference content)
-- ------------------------------------------------------------
create table if not exists insurance_schemes (
  id uuid primary key default uuid_generate_v4(),
  name_en text not null,
  name_mr text not null,
  description_en text,
  description_mr text,
  official_link text
);

alter table insurance_schemes enable row level security;
create policy "Anyone can read insurance schemes"
  on insurance_schemes for select using (true);

-- ------------------------------------------------------------
-- 8. BOOKINGS (seed / fertilizer requests)
-- ------------------------------------------------------------
create table if not exists bookings (
  id uuid primary key default uuid_generate_v4(),
  farmer_id uuid references farmers(id) on delete cascade,
  item_type text check (item_type in ('seed','fertilizer')),
  item_name text not null,
  quantity numeric,
  unit text default 'kg',
  status text default 'pending' check (status in ('pending','confirmed','delivered','cancelled')),
  requested_at timestamptz default now()
);

alter table bookings enable row level security;

create policy "Farmers manage their own bookings"
  on bookings for all
  using (farmer_id in (select id from farmers where auth_id = auth.uid()))
  with check (farmer_id in (select id from farmers where auth_id = auth.uid()));

-- ------------------------------------------------------------
-- 9. ALERTS / NOTIFICATIONS
-- ------------------------------------------------------------
create table if not exists alerts (
  id bigint generated always as identity primary key,
  farmer_id uuid references farmers(id) on delete cascade,
  alert_type text check (alert_type in ('weather','disease','irrigation','emergency','general')),
  title_en text,
  title_mr text,
  message_en text,
  message_mr text,
  sent_at timestamptz default now(),
  read_at timestamptz
);

alter table alerts enable row level security;

create policy "Farmers can view and update their own alerts"
  on alerts for select
  using (farmer_id in (select id from farmers where auth_id = auth.uid()));

create policy "Farmers can mark their own alerts read"
  on alerts for update
  using (farmer_id in (select id from farmers where auth_id = auth.uid()));

-- ============================================================
-- SEED DATA — a few starter crops for testing
-- ============================================================
insert into crops (name_en, name_mr, season, ideal_rainfall_min_mm, ideal_rainfall_max_mm, soil_type, growth_duration_days)
values
  ('Cotton', 'कापूस', 'kharif', 600, 1200, 'Black soil', 180),
  ('Soybean', 'सोयाबीन', 'kharif', 600, 1000, 'Black/loamy soil', 100),
  ('Wheat', 'गहू', 'rabi', 300, 600, 'Loamy soil', 120),
  ('Chickpea (Gram)', 'हरभरा', 'rabi', 250, 500, 'Sandy loam', 100),
  ('Sugarcane', 'ऊस', 'summer', 1500, 2500, 'Deep black soil', 365)
on conflict do nothing;

-- ============================================================
-- End of schema
-- ============================================================
