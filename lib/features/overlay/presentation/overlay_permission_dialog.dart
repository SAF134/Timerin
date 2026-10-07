import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';

/// Dialog penjelasan izin overlay dan panduan bypass Restricted Settings pada Android 13-15 (FR-012).
class OverlayPermissionDialog extends ConsumerWidget {
  const OverlayPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OverlayPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(overlayPermissionServiceProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: AppRadius.cardShape,
      insetPadding: AppSpacing.p16,
      child: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.p24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header Icon & Title
              Row(
                children: <Widget>[
                  Container(
                    padding: AppSpacing.p8,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.cardRadius,
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      size: 28.0,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Text(
                      'Izin Tampil di Atas Aplikasi',
                      style: AppTypography.title20.copyWith(fontSize: 18.0),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // Official PRD Microcopy
              Text(
                "Timerin butuh izin 'Tampil di atas aplikasi lain' hanya untuk menampilkan timer di atas game. Timerin tidak membaca layar atau data game kamu.",
                style: AppTypography.body14.copyWith(
                  color: AppColors.text,
                  height: 1.45,
                ),
              ),
              AppSpacing.gapH24,

              // Primary Action: Open Permission Setting
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await permissionService.requestOverlayPermission();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan Izin'),
              ),
              AppSpacing.gapH24,

              // Section: Android 13+ Restricted Settings Guide
              Container(
                padding: AppSpacing.p16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.info_outline,
                          size: 20.0,
                          color: AppColors.warning,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Text(
                            'Tombol Izin Abu-Abu / Tidak Bisa Ditekan?',
                            style: AppTypography.body14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Di Android 13-15 hasil pemasangan langsung (sideload), ikuti 3 langkah berikut:',
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    AppSpacing.gapH12,
                    _buildStepItem('1', 'Buka Info Aplikasi Timerin'),
                    _buildStepItem(
                      '2',
                      'Ketuk ikon menu 3-titik (⋮) di pojok kanan atas',
                    ),
                    _buildStepItem(
                      '3',
                      'Pilih "Izinkan setelan terbatas" & masukkan PIN/sidik jari',
                    ),
                    AppSpacing.gapH12,
                    OutlinedButton.icon(
                      onPressed: () async {
                        await permissionService.openApplicationSettings();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40.0),
                      ),
                      icon: const Icon(Icons.app_settings_alt, size: 18.0),
                      label: const Text('Buka Setelan Info Aplikasi'),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // Dismiss / Cancel Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Nanti Saja',
                  style: AppTypography.body14.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 18.0,
            height: 18.0,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTypography.caption12.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption12.copyWith(
                color: AppColors.text,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
