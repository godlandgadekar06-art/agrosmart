import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _farmSizeCtrl = TextEditingController();
  String _language = 'mr';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.upsertFarmerProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        village: _villageCtrl.text.trim(),
        taluka: _talukaCtrl.text.trim(),
        preferredLanguage: _language,
        farmSizeAcres: double.tryParse(_farmSizeCtrl.text.trim()),
      );

      final profile = await SupabaseService.instance.getFarmerProfile();
      if (!mounted) return;
      if (profile != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(farmerProfile: profile),
          ),
        );
      } else {
        setState(() => _error = 'Profile saved but could not be loaded. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('profile_setup_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mr', label: Text('मराठी')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {_language},
              onSelectionChanged: (v) => setState(() => _language = v.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(hintText: s.t('name_hint')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: s.t('phone_hint')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _villageCtrl,
              decoration: InputDecoration(hintText: s.t('village_hint')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _talukaCtrl,
              decoration: InputDecoration(hintText: s.t('taluka_hint')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _farmSizeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: s.t('farm_size_hint')),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(s.t('save_continue')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.alertRed),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
