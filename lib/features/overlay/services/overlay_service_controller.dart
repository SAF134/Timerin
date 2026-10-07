import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';

final overlayServiceControllerProvider = Provider<OverlayServiceController>((
  ref,
) {
  final permissionService = ref.watch(overlayPermissionServiceProvider);
  return OverlayServiceController(permissionService: permissionService);
});

class OverlayServiceController {
  OverlayServiceController({
    required OverlayPermissionService permissionService,
  }) : _permissionService = permissionService;

  final OverlayPermissionService _permissionService;

  /// Memeriksa apakah overlay sedang aktif di layar.
  Future<bool> isOverlayActive() async {
    return FlutterOverlayWindow.isActive();
  }

  /// Memulai layanan overlay mengambang beserta notifikasi persisten (FR-010, FR-019).
  /// Mengembalikan `true` jika berhasil diluncurkan, `false` jika izin belum diberikan.
  Future<bool> startOverlay({
    int height = WindowSize.matchParent,
    int width = WindowSize.matchParent,
    OverlayAlignment alignment = OverlayAlignment.centerLeft,
    bool enableDrag = true,
  }) async {
    // 1. Verifikasi izin overlay
    final hasOverlayPermission = await _permissionService
        .isOverlayPermissionGranted();
    if (!hasOverlayPermission) {
      return false;
    }

    // 2. Minta izin notifikasi jika belum diberikan (Android 13+)
    final hasNotificationPermission = await _permissionService
        .isNotificationPermissionGranted();
    if (!hasNotificationPermission) {
      await _permissionService.requestNotificationPermission();
    }

    // 3. Tampilkan overlay dengan foreground service dan notifikasi persisten
    await FlutterOverlayWindow.showOverlay(
      height: height,
      width: width,
      alignment: alignment,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: 'Timerin Aktif',
      overlayContent: 'Timer spell sedang berjalan di atas game.',
      enableDrag: enableDrag,
      positionGravity: PositionGravity.none,
    );

    return true;
  }

  /// Menghentikan layanan overlay dan menghapus notifikasi persisten.
  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
