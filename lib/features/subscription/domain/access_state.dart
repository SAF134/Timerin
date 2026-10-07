import 'package:flutter/foundation.dart';

/// Status akses penggunaan aplikasi Timerin (PRD §3, FR-013, FR-014).
enum AccessStatus {
  /// Akun baru, trial belum dimulai (`trialStartedAt == null`), tidak berlangganan.
  baru,

  /// Trial 24 jam sedang berjalan (`sekarang < trialStartedAt + 24 jam`).
  trial,

  /// Langganan berbayar aktif (`sekarang < subscriptionEndsAt`).
  berlangganan,

  /// Masa trial atau langganan telah habis, overlay terkunci.
  habis,
}

/// State lengkap informasi hak akses pengguna (PRD §3, TECH §5).
@immutable
class AccessState {
  const AccessState({
    required this.status,
    required this.remainingAccess,
    this.serverTime,
    this.trialStartedAt,
    this.subscriptionEndsAt,
  });

  final AccessStatus status;

  /// Sisa durasi masa akses aktif (Duration.zero jika status baru atau habis).
  final Duration remainingAccess;

  /// Waktu server terakhir yang terverifikasi.
  final DateTime? serverTime;

  /// Timestamp dimulainya masa trial 24 jam.
  final DateTime? trialStartedAt;

  /// Timestamp berakhirnya masa langganan aktif.
  final DateTime? subscriptionEndsAt;

  bool get isNew => status == AccessStatus.baru;
  bool get isTrial => status == AccessStatus.trial;
  bool get isSubscribed => status == AccessStatus.berlangganan;
  bool get isExpired => status == AccessStatus.habis;

  /// Apakah pengguna berhak mengaktifkan overlay spell.
  bool get canActivateOverlay => isTrial || isSubscribed;

  /// Format teks ramah pengguna untuk sisa masa akses (SCR-004).
  String get remainingFormatted {
    if (status == AccessStatus.baru) {
      return 'Trial 24 jam siap dimulai';
    }
    if (status == AccessStatus.habis) {
      return 'Masa aktif habis';
    }

    final totalHours = remainingAccess.inHours;
    if (totalHours >= 48) {
      final days = remainingAccess.inDays;
      return 'sisa $days hari';
    }
    if (totalHours >= 1) {
      return 'sisa $totalHours jam';
    }
    final minutes = remainingAccess.inMinutes;
    if (minutes > 0) {
      return 'sisa $minutes menit';
    }
    final seconds = remainingAccess.inSeconds;
    return 'sisa $seconds detik';
  }

  AccessState copyWith({
    AccessStatus? status,
    Duration? remainingAccess,
    DateTime? serverTime,
    DateTime? trialStartedAt,
    DateTime? subscriptionEndsAt,
  }) {
    return AccessState(
      status: status ?? this.status,
      remainingAccess: remainingAccess ?? this.remainingAccess,
      serverTime: serverTime ?? this.serverTime,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessState &&
        other.status == status &&
        other.remainingAccess == remainingAccess &&
        other.serverTime == serverTime &&
        other.trialStartedAt == trialStartedAt &&
        other.subscriptionEndsAt == subscriptionEndsAt;
  }

  @override
  int get hashCode => Object.hash(
    status,
    remainingAccess,
    serverTime,
    trialStartedAt,
    subscriptionEndsAt,
  );
}
