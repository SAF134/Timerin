import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Layanan pelaporan crash Firebase Crashlytics (NFR-009).
/// Mematuhi aturan ketat `AGENTS.md` & `04-SECURITY.md` §5:
/// **DILARANG mencatat email, UID, atau token kredensial ke dalam log Crashlytics.**
abstract final class CrashlyticsService {
  /// Menginisialisasi handler crash Flutter & Platform Dispatcher.
  static Future<void> initialize({FirebaseCrashlytics? instance}) async {
    final crashlytics = instance ?? FirebaseCrashlytics.instance;

    // Aktifkan koleksi crash hanya di luar debug mode (kecuali diinginkan eksplisit)
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Tangkap synchronous Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      crashlytics.recordFlutterFatalError(details);
    };

    // Tangkap asynchronous uncaught errors dari engine platform
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Mencatat non-fatal error tanpa menyertakan PII/UID/token.
  static Future<void> recordNonFatal(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    FirebaseCrashlytics? instance,
  }) async {
    final crashlytics = instance ?? FirebaseCrashlytics.instance;
    await crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: false,
    );
  }
}
