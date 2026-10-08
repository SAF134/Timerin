import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';

final overlayServiceControllerProvider = Provider<OverlayServiceController>((
  ref,
) {
  final permissionService = ref.watch(overlayPermissionServiceProvider);
  return OverlayServiceController(permissionService: permissionService);
});

/// Notifier status aktifnya overlay di layar.
class OverlayActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool active) {
    state = active;
  }

  Future<void> syncWithSystem() async {
    final controller = ref.read(overlayServiceControllerProvider);
    state = await controller.isOverlayActive();
  }
}

final overlayActiveProvider = NotifierProvider<OverlayActiveNotifier, bool>(() {
  return OverlayActiveNotifier();
});

class OverlayServiceController {
  OverlayServiceController({
    required OverlayPermissionService permissionService,
  }) : _permissionService = permissionService;

  final OverlayPermissionService _permissionService;

  /// Menghitung dimensi lebar dan tinggi window native berdasarkan pengaturan timer (FR-005, FR-008, FR-009).
  static ({int width, int height}) calculateWindowDimensions(
    TimerSettings settings,
  ) {
    final bubbleSize = 56.0 * settings.scale;
    final gap = 8.0 * settings.scale;
    final totalLength =
        (settings.timerCount * bubbleSize) + ((settings.timerCount - 1) * gap);

    if (settings.orientation == TimerOrientation.vertical) {
      final width = (bubbleSize + 28.0).ceil();
      final height = (totalLength + 32.0).ceil();
      return (width: width, height: height);
    } else {
      final width = (totalLength + 32.0).ceil();
      final height = (bubbleSize + 28.0).ceil();
      return (width: width, height: height);
    }
  }

  /// Memeriksa apakah overlay sedang aktif di layar.
  Future<bool> isOverlayActive() async {
    return FlutterOverlayWindow.isActive();
  }

  /// Mengambil koordinat posisi saat ini dari jendela overlay (FR-011).
  Future<OverlayPosition?> getCurrentPosition() async {
    try {
      return await FlutterOverlayWindow.getOverlayPosition();
    } catch (_) {
      return null;
    }
  }

  /// Menggeser/memindahkan posisi jendela overlay secara langsung (FR-011).
  Future<bool> moveOverlay(double x, double y) async {
    try {
      final res = await FlutterOverlayWindow.moveOverlay(OverlayPosition(x, y));
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Memulai layanan overlay mengambang beserta notifikasi persisten (FR-010, FR-011, FR-019).
  /// Mengembalikan `true` jika berhasil diluncurkan, `false` jika izin belum diberikan.
  Future<bool> startOverlay({
    TimerSettings? settings,
    int? height,
    int? width,
    OverlayAlignment alignment = OverlayAlignment.topLeft,
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

    // 3. Tentukan ukuran jendela sesuai pengaturan
    final effectiveDimensions = settings != null
        ? calculateWindowDimensions(settings)
        : (width: 220, height: 220);

    final finalWidth = width ?? effectiveDimensions.width;
    final finalHeight = height ?? effectiveDimensions.height;

    // 4. Hitung posisi awal tersimpan jika tersedia (FR-011, SCR-007)
    // Berikan posisi awal aman (16, 160) agar tidak terpotong di status bar jika belum diatur
    final startPos =
        (settings?.positionX != null &&
            settings?.positionY != null &&
            settings!.positionX! >= 0 &&
            settings.positionY! >= 0)
        ? OverlayPosition(settings.positionX!, settings.positionY!)
        : const OverlayPosition(16.0, 160.0);

    // WindowManager Android memerlukan pixel fisik pada showOverlay
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    final pixelRatio = view?.devicePixelRatio ?? 3.0;
    final widthPx = (finalWidth * pixelRatio).ceil();
    final heightPx = (finalHeight * pixelRatio).ceil();

    // 5. Tampilkan overlay dengan foreground service dan notifikasi persisten
    await FlutterOverlayWindow.showOverlay(
      height: heightPx,
      width: widthPx,
      alignment: alignment,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: 'Timerin Aktif',
      overlayContent: 'Timer spell sedang berjalan di atas game.',
      enableDrag: enableDrag,
      positionGravity: PositionGravity.none,
      startPosition: startPos,
    );

    // 6. Sinkronisasi data pengaturan dan resize ke overlay process
    if (settings != null) {
      Future.delayed(const Duration(milliseconds: 250), () {
        FlutterOverlayWindow.shareData(
          settings.toJson(),
        ).catchError((_) => null);
        FlutterOverlayWindow.resizeOverlay(
          finalWidth,
          finalHeight,
          enableDrag,
        ).catchError((_) => null);
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        FlutterOverlayWindow.shareData(
          settings.toJson(),
        ).catchError((_) => null);
        FlutterOverlayWindow.resizeOverlay(
          finalWidth,
          finalHeight,
          enableDrag,
        ).catchError((_) => null);
      });
    }

    return true;
  }

  /// Mengubah ukuran jendela overlay saat sedang berjalan.
  Future<void> updateDimensions(TimerSettings settings) async {
    final dims = calculateWindowDimensions(settings);
    await FlutterOverlayWindow.resizeOverlay(dims.width, dims.height, true);
    await FlutterOverlayWindow.shareData(settings.toJson());
  }

  /// Menghentikan layanan overlay dan menghapus notifikasi persisten.
  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
