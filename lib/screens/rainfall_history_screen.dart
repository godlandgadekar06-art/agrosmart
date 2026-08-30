import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class RainfallHistoryScreen extends StatefulWidget {
  final String deviceId;
  const RainfallHistoryScreen({super.key, required this.deviceId});

  @override
  State<RainfallHistoryScreen> createState() => _RainfallHistoryScreenState();
}

class _RainfallHistoryScreenState extends State<RainfallHistoryScreen> {
  List<Map<String, dynamic>> _readings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance
        .getRainfallHistory(widget.deviceId, days: 30);
    setState(() {
      _readings = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('rainfall_history'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _readings.isEmpty
              ? Center(child: Text(s.t('no_data_yet')))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last 30 days (mm)',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < _readings.length; i++)
                                    FlSpot(
                                      i.toDouble(),
                                      (_readings[i]['rainfall_mm'] as num)
                                          .toDouble(),
                                    ),
                                ],
                                isCurved: true,
                                color: AppColors.rainBlue,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.rainBlue.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
