import 'package:flutter_riverpod/flutter_riverpod.dart';

final cooldownServiceProvider = Provider<CooldownService>((ref) {
  return CooldownService();
});

/// Layanan manajemen cooldown anti-spam untuk request jaringan/server (1 menit / 60 detik).
class CooldownService {
  final Map<String, DateTime> _lastActionTimestamps = <String, DateTime>{};

  static const Duration defaultCooldown = Duration(minutes: 1);

  /// Mengecek apakah suatu aksi dapat dieksekusi berdasarkan jeda cooldown.
  bool canExecute(
    String actionKey, {
    Duration cooldown = defaultCooldown,
    DateTime? now,
  }) {
    final lastTime = _lastActionTimestamps[actionKey];
    if (lastTime == null) return true;
    final currentTime = now ?? DateTime.now();
    return currentTime.difference(lastTime) >= cooldown;
  }

  /// Menghitung sisa waktu cooldown untuk aksi tertentu.
  Duration getRemainingCooldown(
    String actionKey, {
    Duration cooldown = defaultCooldown,
    DateTime? now,
  }) {
    final lastTime = _lastActionTimestamps[actionKey];
    if (lastTime == null) return Duration.zero;
    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(lastTime);
    if (elapsed >= cooldown) return Duration.zero;
    return cooldown - elapsed;
  }

  /// Mencatat waktu eksekusi aksi saat ini.
  void recordExecution(String actionKey, {DateTime? now}) {
    _lastActionTimestamps[actionKey] = now ?? DateTime.now();
  }

  /// Mereset riwayat aksi (terutama untuk pengujian).
  void reset() {
    _lastActionTimestamps.clear();
  }

  /// Memformat sisa durasi menjadi teks ramah pengguna (contoh: "4 menit 30 detik").
  static String formatRemaining(Duration remaining) {
    final totalSeconds = remaining.inSeconds;
    if (totalSeconds <= 0) return '0 detik';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes > 0 && seconds > 0) {
      return '$minutes menit $seconds detik';
    } else if (minutes > 0) {
      return '$minutes menit';
    } else {
      return '$seconds detik';
    }
  }
}
