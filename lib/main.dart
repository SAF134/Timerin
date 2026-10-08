import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/services/crashlytics_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/onboarding/presentation/splash_screen.dart';

import 'package:timerin/overlay_main.dart';

// Export entry point overlay untuk kompatibilitas
export 'package:timerin/overlay_main.dart' show OverlayApp;

/// Entry point khusus untuk proses background flutter_overlay_window.
/// Didefinisikan secara langsung di main.dart agar Flutter Engine dapat
/// menemukan entrypoint saat diluncurkan secara native oleh DartExecutor.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp();
    await CrashlyticsService.initialize();
  } catch (_) {
    // Inisialisasi Firebase dapat dilewati di lingkungan pengujian tanpa config aktif
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const TimerinApp(),
    ),
  );
}

class TimerinApp extends StatelessWidget {
  const TimerinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Timerin',
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
