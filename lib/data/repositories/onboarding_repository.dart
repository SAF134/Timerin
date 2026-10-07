import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs: prefs);
});

class OnboardingRepository {
  OnboardingRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';

  /// Memeriksa apakah pengguna sudah pernah menyelesaikan onboarding (SCR-002).
  bool hasSeenOnboarding() {
    return _prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  /// Menandai bahwa onboarding telah diselesaikan.
  Future<bool> setHasSeenOnboarding(bool value) async {
    return _prefs.setBool(_keyHasSeenOnboarding, value);
  }
}
