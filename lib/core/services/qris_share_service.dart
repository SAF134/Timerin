import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final qrisShareServiceProvider = Provider<QrisShareService>((ref) {
  return const QrisShareService();
});

/// Layanan untuk menyimpan dan membagikan gambar QRIS pembayaran via native platform channel.
class QrisShareService {
  const QrisShareService({
    MethodChannel channel = const MethodChannel('com.timerin.app/vibration'),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Membagikan gambar barcode QRIS ke aplikasi lain (WhatsApp, Telegram, dll).
  Future<bool> shareQris() async {
    try {
      final res = await _channel.invokeMethod<bool>('shareQris');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Menyimpan gambar barcode QRIS ke galeri / penyimpanan perangkat pengguna.
  Future<bool> saveQrisToGallery() async {
    try {
      final res = await _channel.invokeMethod<bool>('saveQris');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
