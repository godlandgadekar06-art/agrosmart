import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/feature_card.dart';
import 'rainfall_history_screen.dart';
import 'crop_recommendation_screen.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> farmerProfile;
  const DashboardScreen({super.key, required this.farmerProfile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _device;
  Map<String, dynamic>? _latestReading;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmerId = widget.farmerProfile['id'] as String;
    final device = await SupabaseService.instance.getDeviceForFarmer(farmerId);
    Map<String, dynamic>? reading;
    if (device != null) {
      reading = await SupabaseService.instance.getLatestRainfall(device['id']);
    }
    setState(() {
      _device = device;
      _latestReading = reading;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final name = widget.farmerProfile['name'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.t('app_name')} — $name'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlertsScreen(farmerId: widget.farmerProfile['id']),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RainfallCard(
                    s: s,
                    reading: _latestReading,
                    hasDevice: _device != null,
                    onTapHistory: _device == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RainfallHistoryScreen(
                                  deviceId: _device!['id'],
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),
                  Text(s.t('crop_recommendations'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      FeatureCard(
                        icon: Icons.eco,
                        label: s.t('crop_recommendations'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropRecommendationScreen(
                              farmerProfile: widget.farmerProfile,
                            ),
                          ),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.water_drop,
                        label: s.t('irrigation_advice'),
                        color: AppColors.rainBlue,
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.wb_sunny_outlined,
                        label: s.t('weather_forecast'),
                        color: AppColors.warningAmber,
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.bug_report_outlined,
                        label: s.t('crop_diseases'),
                        color: AppColors.accentEarth,
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.science_outlined,
                        label: s.t('fertilizers'),
                        color: AppColors.primaryGreenDark,
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.shopping_bag_outlined,
                        label: s.t('book_seeds_fertilizer'),
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.shield_outlined,
                        label: s.t('insurance'),
                        color: AppColors.rainBlue,
                        onTap: () {},
                      ),
                      FeatureCard(
                        icon: Icons.bar_chart,
                        label: s.t('rainfall_history'),
                        color: AppColors.accentEarth,
                        onTap: _device == null
                            ? () {}
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RainfallHistoryScreen(
                                      deviceId: _device!['id'],
                                    ),
                                  ),
                                ),
                      ),
                      FeatureCard(
                        icon: Icons.person_outline,
                        label: s.t('profile'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

/// Prominent card at the top of the dashboard showing the live/last
/// rainfall reading from the farmer's device — this is AgroSmart's core
/// differentiator, so it gets top billing above the feature grid.
class _RainfallCard extends StatelessWidget {
  final AppStrings s;
  final Map<String, dynamic>? reading;
  final bool hasDevice;
  final VoidCallback? onTapHistory;

  const _RainfallCard({
    required this.s,
    required this.reading,
    required this.hasDevice,
    required this.onTapHistory,
  });

  @override
  Widget build(BuildContext context) {
    final mm = reading?['rainfall_mm'];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTapHistory,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.rainBlue, Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('todays_rainfall'),
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasDevice && mm != null
                          ? '$mm ${s.t('mm')}'
                          : s.t('no_data_yet'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTapHistory != null)
                const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
