import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class AlertsScreen extends StatefulWidget {
  final String farmerId;
  const AlertsScreen({super.key, required this.farmerId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.getAlerts(widget.farmerId);
    setState(() {
      _alerts = data;
      _loading = false;
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'weather':
        return Icons.cloud_outlined;
      case 'disease':
        return Icons.bug_report_outlined;
      case 'irrigation':
        return Icons.water_drop_outlined;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'emergency':
        return AppColors.alertRed;
      case 'weather':
        return AppColors.rainBlue;
      case 'disease':
        return AppColors.accentEarth;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = s.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('alerts'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(child: Text(s.t('no_data_yet')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _alerts.length,
                  itemBuilder: (context, i) {
                    final a = _alerts[i];
                    final type = a['alert_type'] as String? ?? 'general';
                    final title =
                        lang == 'mr' ? a['title_mr'] : a['title_en'];
                    final message =
                        lang == 'mr' ? a['message_mr'] : a['message_en'];
                    final isUnread = a['read_at'] == null;

                    return Card(
                      color: isUnread ? Colors.white : const Color(0xFFF1EFE6),
                      child: ListTile(
                        leading: Icon(_iconFor(type), color: _colorFor(type)),
                        title: Text(title ?? '',
                            style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        subtitle: Text(message ?? ''),
                        onTap: () async {
                          if (isUnread) {
                            await SupabaseService.instance
                                .markAlertRead(a['id'] as int);
                            _load();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
