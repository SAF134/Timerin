import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/widgets/timer_settings_card.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

/// Halaman Beranda (M1 Walking Skeleton).
///
/// Menyediakan kontrol peluncuran/penghentian overlay spell (T-005, FR-004, FR-010),
/// panel konfigurasi pengaturan timer lokal (T-007, FR-005..FR-009, FR-018),
/// verifikasi hak akses & waktu server (T-009, FR-013, FR-014),
/// dan navigasi profil/pengaturan.
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
    });
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Menuju halaman Pengaturan (T-011)
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // User Card & Status Akses
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
              AppSpacing.gapH24,

              // Overlay Control Card (T-005, T-009)
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
                                        content: Text('Overlay dinonaktifkan.'),
                                      ),
                                    );
                                }
                              },
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Matikan Overlay'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                            )
                          : ElevatedButton.icon(
                              key: const Key('start_overlay_button'),
                              onPressed: () async {
                                // 1. Verifikasi hak akses (T-009, FR-013, FR-014)
                                if (accessState.isExpired) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Masa aktif telah habis. Silakan berlangganan.',
                                          ),
                                        ),
                                      );
                                  }
                                  return;
                                }

                                if (accessState.isNew) {
                                  final started = await ref
                                      .read(accessStateProvider.notifier)
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

                                // 2. Verifikasi izin overlay (T-006, FR-012)
                                final permissionService = ref.read(
                                  overlayPermissionServiceProvider,
                                );
                                final hasPermission = await permissionService
                                    .isOverlayPermissionGranted();

                                if (!hasPermission) {
                                  if (context.mounted) {
                                    await OverlayPermissionDialog.show(context);
                                  }
                                  return;
                                }

                                // 3. Luncurkan overlay dengan konfigurasi timer (T-005, T-007)
                                final controller = ref.read(
                                  overlayServiceControllerProvider,
                                );
                                final settings = ref.read(
                                  timerSettingsProvider,
                                );
                                final success = await controller.startOverlay(
                                  settings: settings,
                                );
                                if (success) {
                                  ref
                                      .read(overlayActiveProvider.notifier)
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
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // Panel Pengaturan Timer Overlay (T-007)
              const TimerSettingsCard(),
              AppSpacing.gapH24,

              // Logout Button
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
    );
  }
}
