import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/data/repositories/user_repository.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/services/access_cache.dart';
import 'package:timerin/features/subscription/services/monotonic_clock.dart';

final monotonicClockProvider = Provider<MonotonicClock>((ref) {
  return SystemMonotonicClock();
});

final accessCacheProvider = Provider<AccessCache>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccessCache(prefs: prefs);
});

final accessServiceProvider = Provider<AccessService>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final overlayController = ref.watch(overlayServiceControllerProvider);
  final cache = ref.watch(accessCacheProvider);
  final clock = ref.watch(monotonicClockProvider);

  return AccessService(
    userRepository: userRepo,
    overlayController: overlayController,
    cache: cache,
    monotonicClock: clock,
  );
});

/// Notifier state akses reaktif untuk seluruh layar aplikasi (Beranda, Overlay, Langganan).
class AccessNotifier extends Notifier<AccessState> {
  @override
  AccessState build() {
    try {
      final service = ref.watch(accessServiceProvider);
      return service.lastState ?? service.checkAccessOfflineSync();
    } catch (_) {
      return const AccessState(
        status: AccessStatus.baru,
        remainingAccess: Duration.zero,
      );
    }
  }

  /// Sinkronisasi hak akses dengan Firestore / waktu server.
  Future<void> refreshAccess() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    try {
      final service = ref.read(accessServiceProvider);
      state = await service
          .checkAccess(user.uid)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fallback offline jika Firestore lambat/offline
      try {
        final service = ref.read(accessServiceProvider);
        state = service.lastState ?? service.checkAccessOfflineSync();
      } catch (_) {}
    }
  }

  /// Memulai masa trial 24 jam secara atomik (FR-013).
  Future<bool> startTrial() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return false;
    try {
      final service = ref.read(accessServiceProvider);
      final newState = await service.startTrial(user.uid);
      state = newState;
      return newState.status == AccessStatus.trial;
    } catch (_) {
      return false;
    }
  }
}

final accessStateProvider = NotifierProvider<AccessNotifier, AccessState>(() {
  return AccessNotifier();
});

/// Layanan evaluasi akses anti-manipulasi jam (TECH §5, FR-013, FR-014, NFR-001, NFR-004).
class AccessService {
  AccessService({
    required UserRepository userRepository,
    required OverlayServiceController overlayController,
    required AccessCache cache,
    required MonotonicClock monotonicClock,
    String? bootSessionId,
  }) : _userRepository = userRepository,
       _overlayController = overlayController,
       _cache = cache,
       _clock = monotonicClock,
       _bootSessionId =
           bootSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

  final UserRepository _userRepository;
  final OverlayServiceController _overlayController;
  final AccessCache _cache;
  final MonotonicClock _clock;
  final String _bootSessionId;

  static const Duration trialDuration = Duration(hours: 24);

  Timer? _expirationTimer;
  AccessState? _lastState;

  AccessState? get lastState => _lastState;

  /// Evaluasi murni logika hak akses (PRD §3).
  static AccessState evaluateAccess({
    required UserModel user,
    required DateTime serverTime,
  }) {
    // 1. Cek status Berlangganan (Prioritas tertinggi)
    if (user.subscriptionEndsAt != null) {
      if (serverTime.isBefore(user.subscriptionEndsAt!)) {
        final remaining = user.subscriptionEndsAt!.difference(serverTime);
        return AccessState(
          status: AccessStatus.berlangganan,
          remainingAccess: remaining,
          serverTime: serverTime,
          trialStartedAt: user.trialStartedAt,
          subscriptionEndsAt: user.subscriptionEndsAt,
        );
      } else {
        // Langganan telah habis. Periksa apakah trial masih aktif (jika ada)
        if (user.trialStartedAt != null) {
          final trialExpiry = user.trialStartedAt!.add(trialDuration);
          if (serverTime.isBefore(trialExpiry)) {
            final remaining = trialExpiry.difference(serverTime);
            return AccessState(
              status: AccessStatus.trial,
              remainingAccess: remaining,
              serverTime: serverTime,
              trialStartedAt: user.trialStartedAt,
              subscriptionEndsAt: user.subscriptionEndsAt,
            );
          }
        }
        // Jika masa trial juga sudah lewat atau null, status akses HABIS
        return AccessState(
          status: AccessStatus.habis,
          remainingAccess: Duration.zero,
          serverTime: serverTime,
          trialStartedAt: user.trialStartedAt,
          subscriptionEndsAt: user.subscriptionEndsAt,
        );
      }
    }

    // 2. Cek status Trial
    if (user.trialStartedAt != null) {
      final trialExpiry = user.trialStartedAt!.add(trialDuration);
      if (serverTime.isBefore(trialExpiry)) {
        final remaining = trialExpiry.difference(serverTime);
        return AccessState(
          status: AccessStatus.trial,
          remainingAccess: remaining,
          serverTime: serverTime,
          trialStartedAt: user.trialStartedAt,
          subscriptionEndsAt: user.subscriptionEndsAt,
        );
      } else {
        // Trial telah selesai lewat 24 jam
        return AccessState(
          status: AccessStatus.habis,
          remainingAccess: Duration.zero,
          serverTime: serverTime,
          trialStartedAt: user.trialStartedAt,
          subscriptionEndsAt: user.subscriptionEndsAt,
        );
      }
    }

    // 3. Status Baru (belum pernah trial & tidak berlangganan)
    return AccessState(
      status: AccessStatus.baru,
      remainingAccess: Duration.zero,
      serverTime: serverTime,
      trialStartedAt: null,
      subscriptionEndsAt: null,
    );
  }

  /// Memverifikasi hak akses terkini terhadap waktu server dan menghentikan overlay jika habis.
  Future<AccessState> checkAccess(String uid) async {
    try {
      final serverTime = await _userRepository
          .syncServerTime(uid)
          .timeout(const Duration(seconds: 4));
      final user = await _userRepository
          .getUser(uid)
          .timeout(const Duration(seconds: 4));

      if (user == null) {
        throw StateError('Dokumen pengguna tidak ditemukan');
      }

      final accessState = evaluateAccess(user: user, serverTime: serverTime);

      // Simpan ke cache lokal dengan anchor jam monotonik (TECH §5 item 3)
      await _cache.save(
        status: accessState.status,
        remainingMs: accessState.remainingAccess.inMilliseconds,
        monotonicAnchorMs: _clock.elapsedMilliseconds,
        serverTimeMs: serverTime.millisecondsSinceEpoch,
        bootSessionId: _bootSessionId,
        trialStartedMs: user.trialStartedAt?.millisecondsSinceEpoch,
        subscriptionEndsMs: user.subscriptionEndsAt?.millisecondsSinceEpoch,
      );

      _lastState = accessState;

      // Hentikan overlay jika masa akses habis (FR-014)
      if (accessState.status == AccessStatus.habis) {
        await _overlayController.stopOverlay();
      }

      _startWatcher(accessState);
      return accessState;
    } catch (_) {
      // Fallback offline menggunakan cache lokal dan jam monotonik (TECH §5 item 4, NFR-004)
      return _checkAccessOffline();
    }
  }

  /// Evaluasi akses offline secara sinkron dari cache lokal.
  AccessState checkAccessOfflineSync() {
    return _checkAccessOffline();
  }

  /// Evaluasi akses offline berbasis selisih waktu monotonik (kebal ubah jam sistem).
  AccessState _checkAccessOffline() {
    final cached = _cache.load();
    if (cached == null) {
      return const AccessState(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
    }

    final cachedStatus = cached['status'] as AccessStatus;
    if (cachedStatus == AccessStatus.baru ||
        cachedStatus == AccessStatus.habis) {
      return AccessState(status: cachedStatus, remainingAccess: Duration.zero);
    }

    final cachedBoot = cached['bootSession'] as String;
    // Jika sesi boot berubah tanpa ada koneksi online, kunci akses untuk verifikasi ulang
    if (cachedBoot.isNotEmpty && cachedBoot != _bootSessionId) {
      return const AccessState(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
    }

    final cachedRemainingMs = cached['remainingMs'] as int;
    final monotonicAnchorMs = cached['monotonicAnchorMs'] as int;
    final currentMonotonicMs = _clock.elapsedMilliseconds;
    final elapsedMs = currentMonotonicMs - monotonicAnchorMs;

    final effectiveRemainingMs = cachedRemainingMs - elapsedMs;

    if (effectiveRemainingMs <= 0) {
      _overlayController.stopOverlay();
      return const AccessState(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
    }

    final state = AccessState(
      status: cachedStatus,
      remainingAccess: Duration(milliseconds: effectiveRemainingMs),
      trialStartedAt: cached['trialStartedMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(cached['trialStartedMs'] as int)
          : null,
      subscriptionEndsAt: cached['subscriptionEndsMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              cached['subscriptionEndsMs'] as int,
            )
          : null,
    );

    _lastState = state;
    _startWatcher(state);
    return state;
  }

  /// Memulai trial 24 jam secara atomik (FR-013, Anti-Bypass).
  Future<AccessState> startTrial(String uid) async {
    await _userRepository.startTrial(uid);
    return checkAccess(uid);
  }

  /// Memulai pemantau masa kadaluarsa berbasis jam monotonik (stop overlay saat habis).
  void _startWatcher(AccessState state) {
    _expirationTimer?.cancel();
    if (state.status != AccessStatus.trial &&
        state.status != AccessStatus.berlangganan) {
      return;
    }

    final remaining = state.remainingAccess;
    if (remaining <= Duration.zero) {
      _overlayController.stopOverlay();
      return;
    }

    _expirationTimer = Timer(remaining, () async {
      _lastState = _lastState?.copyWith(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
      await _overlayController.stopOverlay();
    });
  }

  void dispose() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }
}
