import 'dart:async';
import 'package:flutter/services.dart';

/// Layanan getaran perangkat fisik dan haptic feedback (T-005, FR-010).
class VibrationService {
  VibrationService._();

  static const MethodChannel _channel = MethodChannel(
    'com.timerin.app/vibration',
  );

  /// Memicu getaran fisik motor perangkat selama [durationMs] (default 2000 ms / 2 detik).
  static Future<void> vibrate({int durationMs = 2000}) async {
    try {
      await _channel.invokeMethod('vibrate', {'durationMs': durationMs});
    } catch (_) {
      // Fallback ke HapticFeedback jika MethodChannel belum terikat
      try {
        await HapticFeedback.vibrate();
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Membatalkan getaran yang sedang aktif.
  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
