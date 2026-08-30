import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme.dart';
import 'l10n/app_strings.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/dashboard_screen.dart';

// Fill these in from Supabase Project Settings > API
const supabaseUrl = 'https://vnjqieavpgfpnyknokqh.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuanFpZWF2cGdmcG55a25va3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwOTI0MzksImV4cCI6MjEwMzY2ODQzOX0.ncgWr94O_FWH-3aqYxBQ_OHzG_Y3svvE0gSxuZNug_A';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const AgroSmartApp());
}

class AgroSmartApp extends StatefulWidget {
  const AgroSmartApp({super.key});

  @override
  State<AgroSmartApp> createState() => _AgroSmartAppState();
}

class _AgroSmartAppState extends State<AgroSmartApp> {
  String _languageCode = 'mr'; // default to Marathi — primary audience

  void _setLanguage(String code) {
    setState(() => _languageCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      languageCode: _languageCode,
      setLanguage: _setLanguage,
      child: MaterialApp(
        title: 'AgroSmart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decides which screen to show based on auth + profile-completion state:
/// not logged in -> Login; logged in but no profile -> Profile setup;
/// logged in with profile -> Dashboard.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: SupabaseService.instance.getFarmerProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return const ProfileSetupScreen();
            }

            // Apply the farmer's saved language preference on load.
            final savedLang = profile['preferred_language'] as String?;
            if (savedLang != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LocaleScope.setterOf(context)(savedLang);
              });
            }

            return DashboardScreen(farmerProfile: profile);
          },
        );
      },
    );
  }
}
