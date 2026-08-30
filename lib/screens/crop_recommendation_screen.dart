import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class CropRecommendationScreen extends StatefulWidget {
  final Map<String, dynamic> farmerProfile;
  const CropRecommendationScreen({super.key, required this.farmerProfile});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  String _season = 'kharif';
  List<Map<String, dynamic>> _crops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // For a real device, sum recent rainfall from rainfall_readings
    // (e.g. last 30 days) and pass that instead of this placeholder.
    // Falls back to browsing all crops for the season if no rainfall
    // total is available yet (new device / no readings).
    const recentRainfallMm = 650.0;

    final matched = await SupabaseService.instance.getRecommendedCrops(
      season: _season,
      recentRainfallMm: recentRainfallMm,
    );

    final result = matched.isNotEmpty
        ? matched
        : await SupabaseService.instance.getCrops(season: _season);

    setState(() {
      _crops = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = _langCode(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('crop_recommendations'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'kharif', label: Text(s.t('season_kharif'))),
                ButtonSegment(value: 'rabi', label: Text(s.t('season_rabi'))),
                ButtonSegment(value: 'summer', label: Text(s.t('season_summer'))),
              ],
              selected: {_season},
              onSelectionChanged: (v) {
                setState(() => _season = v.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _crops.length,
                    itemBuilder: (context, i) {
                      final crop = _crops[i];
                      final name =
                          lang == 'mr' ? crop['name_mr'] : crop['name_en'];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryGreen,
                            child: Icon(Icons.eco, color: Colors.white),
                          ),
                          title: Text(name ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 17)),
                          subtitle: Text(
                            '${crop['ideal_rainfall_min_mm']}–${crop['ideal_rainfall_max_mm']} mm  •  ${crop['soil_type'] ?? ''}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _langCode(BuildContext context) {
    // Reads the same LocaleScope used across the app.
    return AppStrings.of(context).languageCode;
  }
}
