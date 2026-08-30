import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';

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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await SupabaseService.instance.upsertFarmerProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      taluka: _talukaCtrl.text.trim(),
      preferredLanguage: _language,
      farmSizeAcres: double.tryParse(_farmSizeCtrl.text.trim()),
    );
    // AuthGate rebuilds automatically once the profile exists — Supabase's
    // realtime-aware FutureBuilder in main.dart will pick it up on the
    // next auth-state tick. A manual setState/pop isn't needed here since
    // this screen is only ever shown from AuthGate.
    setState(() => _saving = false);
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
            // Language picker first — everything below should render in
            // the chosen language once picked, keeping first impressions
            // in the farmer's own language from the very first field.
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
          ],
        ),
      ),
    );
  }
}
