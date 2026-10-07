import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';

/// Cache lokal data akses untuk mode offline dan proteksi manipulasi jam (TECH §5, NFR-004).
class AccessCache {
  AccessCache({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyStatus = 'access_cache_status';
  static const String _keyRemainingMs = 'access_cache_remaining_ms';
  static const String _keyMonotonicAnchorMs =
      'access_cache_monotonic_anchor_ms';
  static const String _keyServerTimeMs = 'access_cache_server_time_ms';
  static const String _keyBootSession = 'access_cache_boot_session';
  static const String _keyTrialStartedMs = 'access_cache_trial_started_ms';
  static const String _keySubscriptionEndsMs = 'access_cache_sub_ends_ms';

  Future<void> save({
    required AccessStatus status,
    required int remainingMs,
    required int monotonicAnchorMs,
    required int serverTimeMs,
    required String bootSessionId,
    int? trialStartedMs,
    int? subscriptionEndsMs,
  }) async {
    await _prefs.setString(_keyStatus, status.name);
    await _prefs.setInt(_keyRemainingMs, remainingMs);
    await _prefs.setInt(_keyMonotonicAnchorMs, monotonicAnchorMs);
    await _prefs.setInt(_keyServerTimeMs, serverTimeMs);
    await _prefs.setString(_keyBootSession, bootSessionId);
    if (trialStartedMs != null) {
      await _prefs.setInt(_keyTrialStartedMs, trialStartedMs);
    } else {
      await _prefs.remove(_keyTrialStartedMs);
    }
    if (subscriptionEndsMs != null) {
      await _prefs.setInt(_keySubscriptionEndsMs, subscriptionEndsMs);
    } else {
      await _prefs.remove(_keySubscriptionEndsMs);
    }
  }

  Map<String, dynamic>? load() {
    final statusName = _prefs.getString(_keyStatus);
    if (statusName == null) return null;

    final remainingMs = _prefs.getInt(_keyRemainingMs) ?? 0;
    final monotonicAnchorMs = _prefs.getInt(_keyMonotonicAnchorMs) ?? 0;
    final serverTimeMs = _prefs.getInt(_keyServerTimeMs) ?? 0;
    final bootSession = _prefs.getString(_keyBootSession) ?? '';
    final trialStartedMs = _prefs.getInt(_keyTrialStartedMs);
    final subscriptionEndsMs = _prefs.getInt(_keySubscriptionEndsMs);

    final status = AccessStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => AccessStatus.habis,
    );

    return <String, dynamic>{
      'status': status,
      'remainingMs': remainingMs,
      'monotonicAnchorMs': monotonicAnchorMs,
      'serverTimeMs': serverTimeMs,
      'bootSession': bootSession,
      'trialStartedMs': trialStartedMs,
      'subscriptionEndsMs': subscriptionEndsMs,
    };
  }

  Future<void> clear() async {
    await _prefs.remove(_keyStatus);
    await _prefs.remove(_keyRemainingMs);
    await _prefs.remove(_keyMonotonicAnchorMs);
    await _prefs.remove(_keyServerTimeMs);
    await _prefs.remove(_keyBootSession);
    await _prefs.remove(_keyTrialStartedMs);
    await _prefs.remove(_keySubscriptionEndsMs);
  }
}
