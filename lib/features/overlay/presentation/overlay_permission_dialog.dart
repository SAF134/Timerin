import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';

/// Dialog penjelasan izin overlay (FR-012, SCR-004).
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
                textAlign: TextAlign.justify,
              ),
              AppSpacing.gapH24,

              // Primary Action: Open Permission Setting
              ElevatedButton.icon(
                key: const Key('open_permission_setting_button'),
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await permissionService.requestOverlayPermission();
                },
                icon: const Icon(Icons.settings, size: 16.0),
                label: const Text(
                  'Izinkan Pengaturan Overlay Aplikasi',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonRadius,
                  ),
                  elevation: 2.0,
                  minimumSize: const Size.fromHeight(40.0),
                ),
              ),
              AppSpacing.gapH12,

              // Dismiss / Cancel Button: OutlinedButton
              OutlinedButton(
                key: const Key('overlay_permission_later_button'),
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonRadius,
                  ),
                  minimumSize: const Size.fromHeight(44.0),
                ),
                child: const Text('Nanti Saja'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
