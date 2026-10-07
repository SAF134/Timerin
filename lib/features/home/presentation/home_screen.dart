import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/core/widgets/app_update_dialog.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/widgets/access_status_banner.dart';
import 'package:timerin/features/home/presentation/widgets/timer_settings_card.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/settings/presentation/settings_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final userModelAsync = ref.watch(currentUserModelProvider);
    final authUser = ref.watch(authServiceProvider).currentUser;
    final isOverlayActive = ref.watch(overlayActiveProvider);
    final accessState = ref.watch(accessStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Timerin'),
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
                // 1. User Card
                Container(
                  padding: AppSpacing.p24,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                  ),
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
                                  : AppColors.accent.withValues(alpha: 0.1),
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
                      Text(
                        userModelAsync.value?.displayName.isNotEmpty == true
                            ? userModelAsync.value!.displayName
                            : authUser?.displayName ?? 'Pemain',
                        style: AppTypography.title20,
                      ),
                      AppSpacing.gapH8,
                      Text(
                        authUser?.email ?? '',
                        style: AppTypography.body14Muted,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,

                // 2. Banner Status Akses (SCR-004, FR-004, FR-014)
                AccessStatusBanner(
                  accessState: accessState,
                  onSubscribePressed: _navigateToSubscription,
                ),
                AppSpacing.gapH24,

                // 3. Overlay Control Card (T-005, T-009, FR-014)
                Container(
                  padding: AppSpacing.p24,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: isOverlayActive
                          ? AppColors.accent
                          : AppColors.border,
                      width: isOverlayActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.timer_outlined,
                            color: isOverlayActive
                                ? AppColors.accent
                                : AppColors.primary,
                            size: 24.0,
                          ),
                          AppSpacing.gapW12,
                          const Text(
                            'Overlay Spell',
                            style: AppTypography.title20,
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      const Text(
                        'Tampilkan timer spell mengambang di atas game Mobile Legends.',
                        style: AppTypography.body14Muted,
                      ),
                      AppSpacing.gapH16,
                      Row(
                        children: <Widget>[
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: isOverlayActive
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Text(
                            isOverlayActive
                                ? 'Status: Aktif'
                                : 'Status: Nonaktif',
                            style: AppTypography.body14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOverlayActive
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,
                      SizedBox(
                        width: double.infinity,
                        child: isOverlayActive
                            ? OutlinedButton.icon(
                                key: const Key('stop_overlay_button'),
                                onPressed: () async {
                                  final controller = ref.read(
                                    overlayServiceControllerProvider,
                                  );
                                  await controller.stopOverlay();
                                  ref
                                      .read(overlayActiveProvider.notifier)
                                      .setActive(false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Overlay dinonaktifkan.',
                                          ),
                                        ),
                                      );
                                  }
                                },
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Matikan Overlay'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                key: const Key('start_overlay_button'),
                                // Tombol nonaktif jika akses telah HABIS (FR-014, SCR-004)
                                onPressed: accessState.isExpired
                                    ? null
                                    : () async {
                                        if (accessState.isNew) {
                                          final started = await ref
                                              .read(
                                                accessStateProvider.notifier,
                                              )
                                              .startTrial();
                                          if (!started) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                ..hideCurrentSnackBar()
                                                ..showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Gagal memulai trial. Periksa koneksi internet.',
                                                    ),
                                                  ),
                                                );
                                            }
                                            return;
                                          }
                                        }

                                        // Verifikasi izin overlay (T-006, FR-012)
                                        final permissionService = ref.read(
                                          overlayPermissionServiceProvider,
                                        );
                                        final hasPermission =
                                            await permissionService
                                                .isOverlayPermissionGranted();

                                        if (!hasPermission) {
                                          if (context.mounted) {
                                            await OverlayPermissionDialog.show(
                                              context,
                                            );
                                          }
                                          return;
                                        }

                                        // Luncurkan overlay dengan konfigurasi timer (T-005, T-007)
                                        final controller = ref.read(
                                          overlayServiceControllerProvider,
                                        );
                                        final settings = ref.read(
                                          timerSettingsProvider,
                                        );
                                        final success = await controller
                                            .startOverlay(settings: settings);
                                        if (success) {
                                          ref
                                              .read(
                                                overlayActiveProvider.notifier,
                                              )
                                              .setActive(true);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Overlay spell telah diaktifkan.',
                                                  ),
                                                ),
                                              );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Aktifkan Overlay'),
                              ),
                      ),
                      if (accessState.isExpired) ...<Widget>[
                        AppSpacing.gapH8,
                        Text(
                          'Tombol overlay dinonaktifkan karena masa akses telah selesai.',
                          style: AppTypography.caption12.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // 4. Panel Pengaturan Timer Overlay & Pratinjau (T-007, SCR-004)
                const TimerSettingsCard(),
                AppSpacing.gapH24,

                // 5. Logout Button
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
