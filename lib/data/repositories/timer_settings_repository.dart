import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';

final timerSettingsRepositoryProvider = Provider<TimerSettingsRepository>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TimerSettingsRepository(prefs: prefs);
});

final timerSettingsProvider =
    NotifierProvider<TimerSettingsNotifier, TimerSettings>(() {
      return TimerSettingsNotifier();
    });

/// Notifier pengelola state pengaturan timer lokal secara reaktif (FR-018).
class TimerSettingsNotifier extends Notifier<TimerSettings> {
  @override
  TimerSettings build() {
    final repo = ref.watch(timerSettingsRepositoryProvider);
    return repo.getSettings();
  }

  TimerSettingsRepository get _repo =>
      ref.read(timerSettingsRepositoryProvider);

  /// Memperbarui pengaturan dan menyimpannya ke `SharedPreferences`.
  Future<void> updateSettings(TimerSettings newSettings) async {
    state = newSettings;
    await _repo.saveSettings(newSettings);
    _syncToRunningOverlay(newSettings);
  }

  /// Mengubah jumlah timer aktif (1–5) (FR-005).
  Future<void> setTimerCount(int count) async {
    await updateSettings(state.copyWith(timerCount: count));
  }

  /// Mengubah format waktu tampilan (FR-006).
  Future<void> setTimeFormat(TimeDisplayFormat format) async {
    await updateSettings(state.copyWith(timeFormat: format));
  }

  /// Mengubah orientasi susunan timer (FR-009).
  Future<void> setOrientation(TimerOrientation orientation) async {
    await updateSettings(state.copyWith(orientation: orientation));
  }

  /// Mengubah skala ukuran timer (0.5 – 1.5) (FR-008).
  Future<void> setScale(double scale) async {
    await updateSettings(state.copyWith(scale: scale));
  }

  /// Mengubah durasi timer ke-[index] dalam detik (FR-007).
  Future<void> setTimerDuration(int index, int seconds) async {
    await updateSettings(state.copyWithDuration(index, seconds));
  }

  /// Sinkronisasi pengaturan ke jendela overlay jika sedang aktif.
  void _syncToRunningOverlay(TimerSettings settings) {
    try {
      FlutterOverlayWindow.shareData(settings.toJson()).catchError((_) => null);
    } catch (_) {
      // Abaikan jika method channel overlay belum aktif
    }
  }
}

/// Repositori penyimpanan lokal pengaturan timer overlay (FR-018, TECH §2).
class TimerSettingsRepository {
  TimerSettingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keySettings = 'timer_settings';

  /// Membaca konfigurasi pengaturan timer dari penyimpanan lokal.
  TimerSettings getSettings() {
    final rawJson = _prefs.getString(_keySettings);
    if (rawJson == null || rawJson.isEmpty) {
      return const TimerSettings();
    }
    return TimerSettings.fromJson(rawJson);
  }

  /// Menyimpan konfigurasi pengaturan timer ke penyimpanan lokal.
  Future<bool> saveSettings(TimerSettings settings) async {
    return _prefs.setString(_keySettings, settings.toJson());
  }
}
