import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';

const String _kPrivacyModeKey = 'is_account_privacy_mode_enabled';

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(() {
  return PrivacyModeNotifier();
});

/// Notifier pengelola mode privasi akun (menyembunyikan foto, email, dan UID menjadi ****).
class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_kPrivacyModeKey) ?? false;
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  /// Mengaktifkan atau menonaktifkan mode privasi akun.
  Future<void> toggle() async {
    final nextState = !state;
    state = nextState;
    await _prefs.setBool(_kPrivacyModeKey, nextState);
  }

  /// Menetapkan status mode privasi akun secara eksplisit.
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_kPrivacyModeKey, enabled);
  }
}
