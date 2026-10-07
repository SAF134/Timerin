import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final overlayPermissionServiceProvider = Provider<OverlayPermissionService>((
  ref,
) {
  return OverlayPermissionService();
});

class OverlayPermissionService {
  /// Memeriksa apakah izin "Tampil di atas aplikasi lain" (`SYSTEM_ALERT_WINDOW`) sudah diberikan.
  Future<bool> isOverlayPermissionGranted() async {
    return FlutterOverlayWindow.isPermissionGranted();
  }

  /// Meminta izin "Tampil di atas aplikasi lain".
  /// Membuka halaman setelan sistem dan mengembalikan status setelah pengguna kembali.
  Future<bool?> requestOverlayPermission() async {
    return FlutterOverlayWindow.requestPermission();
  }

  /// Memeriksa apakah izin notifikasi (`POST_NOTIFICATIONS`) sudah diberikan (Android 13+).
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Meminta izin notifikasi untuk foreground service persisten.
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Membuka halaman Info Aplikasi di Setelan Sistem Android
  /// (Digunakan untuk panduan bypass Restricted Settings pada Android 13+).
  Future<bool> openApplicationSettings() async {
    return openAppSettings();
  }
}
