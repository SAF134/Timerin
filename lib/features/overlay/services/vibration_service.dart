import 'dart:async';
import 'package:flutter/services.dart';

/// Layanan getaran perangkat fisik dan haptic feedback (T-005, FR-010).
class VibrationService {
  VibrationService._();

  static const MethodChannel _channel = MethodChannel(
    'com.timerin.app/vibration',
  );

  /// Menginisialisasi channel getaran pada engine proses background overlay.
  static Future<void> initializeOverlayChannel() async {
    try {
      await _channel.invokeMethod('initOverlayChannel');
    } catch (_) {}
  }

  /// Memicu getaran fisik motor perangkat selama [durationMs] (default 1000 ms / 1 detik).
  static Future<void> vibrate({int durationMs = 1000}) async {
    try {
      await _channel.invokeMethod('vibrate', {'durationMs': durationMs});
    } catch (_) {
      // Fallback ke HapticFeedback jika MethodChannel belum terikat
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Memeriksa apakah fitur umpan balik haptik sistem aktif di perangkat.
  static Future<bool> isHapticFeedbackEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isHapticFeedbackEnabled',
      );
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Membuka pengaturan suara dan getaran haptik sistem perangkat.
  static Future<void> openHapticSettings() async {
    try {
      await _channel.invokeMethod('openHapticSettings');
    } catch (_) {}
  }

  /// Membatalkan getaran yang sedang aktif.
  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
