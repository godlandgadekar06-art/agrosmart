import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Supabase expects E.164 format; assume India (+91) if not provided.
      final formatted = phone.startsWith('+') ? phone : '+91$phone';
      await SupabaseService.instance.signInWithPhone(formatted);
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = 'Could not send OTP. Check connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phoneController.text.trim();
      final formatted = phone.startsWith('+') ? phone : '+91$phone';
      await SupabaseService.instance.verifyOtp(
        formatted,
        _otpController.text.trim(),
      );
      // AuthGate (in main.dart) listens for auth state changes and will
      // automatically navigate on success — nothing else to do here.
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.agriculture, size: 80, color: AppColors.primaryGreen),
              const SizedBox(height: 12),
              Text(
                s.t('app_name'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                s.t('login_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: s.t('phone_hint'),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(s.t('send_otp')),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, letterSpacing: 4),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: s.t('enter_otp')),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(s.t('verify')),
                ),
              ],
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
      ),
    );
  }
}
