/// Simple, dependency-free translation map for Marathi + English.
/// Deliberately avoids the .arb/codegen localization pipeline so the
/// whole team (including non-Flutter contributors) can edit strings.mr.json
/// -style text directly in one readable file.
///
/// Usage: AppStrings.of(context).t('dashboard_title')
library;

import 'package:flutter/widgets.dart';

class AppStrings {
  final String languageCode; // 'en' or 'mr'

  AppStrings(this.languageCode);

  static AppStrings of(BuildContext context) {
    final lang = LocaleScope.of(context);
    return AppStrings(lang);
  }

  static const Map<String, Map<String, String>> _strings = {
    'app_name': {'en': 'AgroSmart', 'mr': 'अ‍ॅग्रोस्मार्ट'},
    'login_title': {'en': 'Welcome to AgroSmart', 'mr': 'अ‍ॅग्रोस्मार्टमध्ये आपले स्वागत आहे'},
    'phone_hint': {'en': 'Enter mobile number', 'mr': 'मोबाईल नंबर टाका'},
    'send_otp': {'en': 'Send OTP', 'mr': 'ओटीपी पाठवा'},
    'enter_otp': {'en': 'Enter OTP', 'mr': 'ओटीपी टाका'},
    'verify': {'en': 'Verify', 'mr': 'पडताळणी करा'},
    'profile_setup_title': {'en': 'Tell us about your farm', 'mr': 'तुमच्या शेताबद्दल सांगा'},
    'name_hint': {'en': 'Full name', 'mr': 'पूर्ण नाव'},
    'village_hint': {'en': 'Village', 'mr': 'गाव'},
    'taluka_hint': {'en': 'Taluka', 'mr': 'तालुका'},
    'farm_size_hint': {'en': 'Farm size (acres)', 'mr': 'शेताचे क्षेत्रफळ (एकर)'},
    'save_continue': {'en': 'Save & Continue', 'mr': 'जतन करा आणि पुढे जा'},
    'dashboard_title': {'en': 'Dashboard', 'mr': 'डॅशबोर्ड'},
    'todays_rainfall': {'en': "Today's Rainfall", 'mr': 'आजचा पाऊस'},
    'weather_forecast': {'en': 'Weather Forecast', 'mr': 'हवामान अंदाज'},
    'crop_recommendations': {'en': 'Crop Recommendations', 'mr': 'पीक शिफारसी'},
    'rainfall_history': {'en': 'Rainfall History', 'mr': 'पावसाचा इतिहास'},
    'irrigation_advice': {'en': 'Irrigation Advice', 'mr': 'सिंचन सल्ला'},
    'crop_diseases': {'en': 'Crop Diseases', 'mr': 'पीक रोग'},
    'fertilizers': {'en': 'Fertilizers', 'mr': 'खते'},
    'book_seeds_fertilizer': {'en': 'Book Seeds / Fertilizer', 'mr': 'बियाणे / खत बुक करा'},
    'insurance': {'en': 'Crop Insurance', 'mr': 'पीक विमा'},
    'alerts': {'en': 'Alerts', 'mr': 'सूचना'},
    'no_data_yet': {'en': 'No data yet', 'mr': 'अजून डेटा उपलब्ध नाही'},
    'mm': {'en': 'mm', 'mr': 'मिमी'},
    'listen': {'en': 'Speak', 'mr': 'बोला'},
    'profile': {'en': 'Profile', 'mr': 'प्रोफाइल'},
    'logout': {'en': 'Logout', 'mr': 'बाहेर पडा'},
    'view_all': {'en': 'View All', 'mr': 'सर्व पहा'},
    'season_kharif': {'en': 'Kharif (Monsoon)', 'mr': 'खरीप (पावसाळी)'},
    'season_rabi': {'en': 'Rabi (Winter)', 'mr': 'रब्बी (हिवाळी)'},
    'season_summer': {'en': 'Summer', 'mr': 'उन्हाळी'},
  };

  String t(String key) {
    return _strings[key]?[languageCode] ?? _strings[key]?['en'] ?? key;
  }
}

/// A super-light InheritedWidget so any screen can read the current
/// language without threading it through every constructor. The farmer's
/// saved preferred_language (from Supabase) sets this once at app start,
/// and a settings toggle can update it at runtime.
class LocaleScope extends InheritedWidget {
  final String languageCode;
  final void Function(String) setLanguage;

  const LocaleScope({
    super.key,
    required this.languageCode,
    required this.setLanguage,
    required super.child,
  });

  static String of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    return scope?.languageCode ?? 'mr';
  }

  static void Function(String) setterOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    return scope?.setLanguage ?? (_) {};
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) =>
      oldWidget.languageCode != languageCode;
}
