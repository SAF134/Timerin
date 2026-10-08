import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/core/widgets/app_update_dialog.dart';
import 'package:timerin/data/repositories/privacy_mode_repository.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/widgets/timer_settings_card.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/settings/presentation/settings_screen.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

/// Halaman Beranda lengkap (SCR-004, FR-004, FR-014, FR-016).
///
/// Menyediakan:
/// - Banner status hak akses 4-state terintegrasi [AccessService] ([AccessStatusBanner]).
/// - Kontrol peluncuran/penghentian overlay spell (dinonaktifkan jika habis).
/// - Penarikan segarkan ([RefreshIndicator]) untuk sinkronisasi waktu server (FR-016).
/// - Panel konfigurasi pengaturan timer lokal dan pratinjau langsung ([TimerSettingsCard]).
/// - Navigasi ke [SubscriptionScreen] (SCR-005) dan [SettingsScreen] (SCR-006).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accessStateProvider.notifier).refreshAccess();
      _checkOptionalUpdate();
    });
  }

  Future<void> _checkOptionalUpdate() async {
    try {
      final updateService = ref.read(appUpdateServiceProvider);
      final updateInfo = await updateService.checkUpdate();
      if (!mounted) return;
      if (updateInfo.hasUpdate) {
        await AppUpdateDialog.show(context, updateInfo);
      }
    } catch (_) {
      // Abaikan jika offline / gagal koneksi
    }
  }

  void _navigateToSubscription() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  Future<void> _handleStopOverlay() async {
    final controller = ref.read(overlayServiceControllerProvider);
    await controller.stopOverlay();
    ref.read(overlayActiveProvider.notifier).setActive(false);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Overlay dinonaktifkan.')));
    }
  }

  void _showExpiredDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text('Masa Akses Habis', style: AppTypography.title20),
          content: const Text(
            'Masa trial atau langganan akun Anda telah berakhir. Segera berlangganan untuk dapat menggunakan fitur overlay timer ini kembali.',
            style: AppTypography.body14,
            textAlign: TextAlign.justify,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
          actions: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _navigateToSubscription();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Langganan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleStartOverlay(AccessState accessState) async {
    if (accessState.isExpired) {
      _showExpiredDialog();
      return;
    }

    if (accessState.isNew) {
      final started = await ref.read(accessStateProvider.notifier).startTrial();
      if (!started) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Gagal memulai trial. Periksa koneksi internet.'),
              ),
            );
        }
        return;
      }
    }

    final permissionService = ref.read(overlayPermissionServiceProvider);
    final hasPermission = await permissionService.isOverlayPermissionGranted();

    if (!hasPermission) {
      if (mounted) {
        await OverlayPermissionDialog.show(context);
      }
      return;
    }

    final controller = ref.read(overlayServiceControllerProvider);
    final settings = ref.read(timerSettingsProvider);
    final success = await controller.startOverlay(settings: settings);
    if (success) {
      ref.read(overlayActiveProvider.notifier).setActive(true);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Overlay aktif. Ketuk 1x untuk mulai timer, ketuk 2x untuk reset.',
              ),
              action: SnackBarAction(
                label: 'Cek Izin',
                textColor: AppColors.accent,
                onPressed: () => OverlayPermissionDialog.show(context),
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModelAsync = ref.watch(currentUserModelProvider);
    final authUser = ref.watch(authServiceProvider).currentUser;
    final isOverlayActive = ref.watch(overlayActiveProvider);
    final accessState = ref.watch(accessStateProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/images/timerin.png',
              width: 32.0,
              height: 32.0,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.timer_outlined,
                size: 26.0,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapW8,
            const Text('Timerin'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('home_settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToSettings,
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: const Key('home_refresh_indicator'),
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(accessStateProvider.notifier).refreshAccess();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.p24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. User Card dengan Foto Profil Google & Mode Privasi
                Container(
                  padding: AppSpacing.p24,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.primary, width: 1.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26.0,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage:
                            (!isPrivacyMode &&
                                authUser?.photoURL != null &&
                                authUser!.photoURL!.isNotEmpty)
                            ? NetworkImage(authUser.photoURL!)
                            : null,
                        onBackgroundImageError:
                            (!isPrivacyMode &&
                                authUser?.photoURL != null &&
                                authUser!.photoURL!.isNotEmpty)
                            ? (_, _) {}
                            : null,
                        child:
                            (isPrivacyMode ||
                                authUser?.photoURL == null ||
                                authUser!.photoURL!.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 30.0,
                              )
                            : null,
                      ),
                      AppSpacing.gapW16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Selamat Datang,',
                                  style: AppTypography.caption12,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accessState.isExpired
                                        ? AppColors.error.withValues(alpha: 0.1)
                                        : AppColors.accent.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: AppRadius.buttonRadius,
                                  ),
                                  child: Text(
                                    accessState.remainingFormatted,
                                    style: AppTypography.caption12.copyWith(
                                      color: accessState.isExpired
                                          ? AppColors.error
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH4,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    userModelAsync
                                                .value
                                                ?.displayName
                                                .isNotEmpty ==
                                            true
                                        ? userModelAsync.value!.displayName
                                        : authUser?.displayName ?? 'Pemain',
                                    style: AppTypography.title20,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  key: const Key('home_privacy_toggle_button'),
                                  icon: Icon(
                                    isPrivacyMode
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20.0,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: isPrivacyMode
                                      ? 'Tampilkan Info Akun'
                                      : 'Sembunyikan Info Akun',
                                  onPressed: () {
                                    ref
                                        .read(privacyModeProvider.notifier)
                                        .toggle();
                                  },
                                ),
                              ],
                            ),
                            AppSpacing.gapH4,
                            Text(
                              isPrivacyMode ? '****' : (authUser?.email ?? ''),
                              style: AppTypography.body14Muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,

                // 2. Panel Pengaturan Timer Overlay & Pratinjau (T-007, SCR-004)
                TimerSettingsCard(isLocked: isOverlayActive),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10.0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (accessState.isExpired) ...<Widget>[
                Text(
                  'Masa akses telah berakhir. Ketuk tombol untuk memperpanjang langganan.',
                  style: AppTypography.caption12.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH8,
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isOverlayActive
                    ? Column(
                        key: const Key('stop_overlay_column'),
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          OutlinedButton.icon(
                            key: const Key('stop_overlay_button'),
                            onPressed: _handleStopOverlay,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Matikan Overlay'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size.fromHeight(48.0),
                            ),
                          ),
                          AppSpacing.gapH8,
                          GestureDetector(
                            key: const Key('home_xiaomi_permission_guide'),
                            onTap: () => OverlayPermissionDialog.show(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.help_outline_rounded,
                                    size: 14.0,
                                    color: AppColors.accent,
                                  ),
                                  AppSpacing.gapW4,
                                  Text(
                                    'Overlay belum muncul? Panduan izin Xiaomi',
                                    style: AppTypography.caption12.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        key: const Key('start_overlay_button'),
                        onPressed: () => _handleStartOverlay(accessState),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Aktifkan Overlay'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48.0),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
