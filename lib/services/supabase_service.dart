import 'package:supabase_flutter/supabase_flutter.dart';

/// Central wrapper around all Supabase calls used across the app.
/// Keeping every query in one place makes it easy to see the app's full
/// data footprint and to change the schema later without hunting through
/// every screen.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------- AUTH ----------------

  Future<void> signInWithPhone(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String token) {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() => _client.auth.signOut();

  // ---------------- FARMER PROFILE ----------------

  Future<Map<String, dynamic>?> getFarmerProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('farmers')
        .select()
        .eq('auth_id', userId)
        .maybeSingle();
    return data;
  }

  Future<void> upsertFarmerProfile({
    required String name,
    required String phone,
    String? village,
    String? taluka,
    String? district,
    String preferredLanguage = 'mr',
    double? farmSizeAcres,
    String? soilType,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client.from('farmers').upsert({
      'auth_id': userId,
      'name': name,
      'phone': phone,
      'village': village,
      'taluka': taluka,
      'district': district,
      'preferred_language': preferredLanguage,
      'farm_size_acres': farmSizeAcres,
      'soil_type': soilType,
    });
  }

  // ---------------- RAINFALL ----------------

  /// Latest single reading for a device (used on the dashboard).
  Future<Map<String, dynamic>?> getLatestRainfall(String deviceId) async {
    final data = await _client
        .from('rainfall_readings')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data;
  }

  /// Rainfall history for graphing, most recent [days] days.
  Future<List<Map<String, dynamic>>> getRainfallHistory(
    String deviceId, {
    int days = 30,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final data = await _client
        .from('rainfall_readings')
        .select()
        .eq('device_id', deviceId)
        .gte('recorded_at', since.toIso8601String())
        .order('recorded_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Live updates — call this to get a stream of new readings as the
  /// ESP32 reports them, for the dashboard's "live" indicator.
  Stream<List<Map<String, dynamic>>> watchRainfall(String deviceId) {
    return _client
        .from('rainfall_readings')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(20);
  }

  Future<Map<String, dynamic>?> getDeviceForFarmer(String farmerId) async {
    final data = await _client
        .from('rain_gauge_devices')
        .select()
        .eq('owner_farmer_id', farmerId)
        .maybeSingle();
    return data;
  }

  // ---------------- CROPS & RECOMMENDATIONS ----------------

  Future<List<Map<String, dynamic>>> getCrops({String? season}) async {
    var query = _client.from('crops').select();
    if (season != null) {
      query = query.eq('season', season);
    }
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Simple rule-based recommendation: given a season and a recent
  /// rainfall total (mm), find crops whose ideal rainfall range matches.
  /// This mirrors the logic in crop_recommendation_rules but can also
  /// run directly against the `crops` table for a quick first pass.
  Future<List<Map<String, dynamic>>> getRecommendedCrops({
    required String season,
    required double recentRainfallMm,
  }) async {
    final data = await _client
        .from('crops')
        .select()
        .eq('season', season)
        .lte('ideal_rainfall_min_mm', recentRainfallMm)
        .gte('ideal_rainfall_max_mm', recentRainfallMm);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRecommendationRules(
    String cropId,
  ) async {
    final data = await _client
        .from('crop_recommendation_rules')
        .select()
        .eq('crop_id', cropId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCropDiseases(String cropId) async {
    final data =
        await _client.from('crop_diseases').select().eq('crop_id', cropId);
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- BOOKINGS ----------------

  Future<void> createBooking({
    required String farmerId,
    required String itemType, // 'seed' | 'fertilizer'
    required String itemName,
    required double quantity,
    String unit = 'kg',
  }) async {
    await _client.from('bookings').insert({
      'farmer_id': farmerId,
      'item_type': itemType,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
    });
  }

  Future<List<Map<String, dynamic>>> getBookings(String farmerId) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('farmer_id', farmerId)
        .order('requested_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- ALERTS ----------------

  Future<List<Map<String, dynamic>>> getAlerts(String farmerId) async {
    final data = await _client
        .from('alerts')
        .select()
        .eq('farmer_id', farmerId)
        .order('sent_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAlertRead(int alertId) async {
    await _client
        .from('alerts')
        .update({'read_at': DateTime.now().toIso8601String()}).eq(
            'id', alertId);
  }

  // ---------------- INSURANCE ----------------

  Future<List<Map<String, dynamic>>> getInsuranceSchemes() async {
    final data = await _client.from('insurance_schemes').select();
    return List<Map<String, dynamic>>.from(data);
  }
}
