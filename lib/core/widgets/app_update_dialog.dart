import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Dialog konfirmasi dan instruksi pembaruan versi aplikasi (FR-020, SECURITY §3).
class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key, required this.info});

  final AppUpdateInfo info;

  /// Menampilkan [AppUpdateDialog] dengan konfigurasi dismissible yang sesuai.
  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (_) => PopScope(
        canPop: !info.isForceUpdate,
        child: AppUpdateDialog(info: info),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isForce = info.isForceUpdate;
    final versionName = info.latestVersionName ?? 'Terbaru';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: AppColors.primary, width: 1.0),
      ),
      contentPadding: AppSpacing.p24,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Icon Header & Versi Badge
          Center(
            child: Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: isForce
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isForce
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isForce
                    ? Icons.system_security_update_rounded
                    : Icons.rocket_launch_rounded,
                size: 30.0,
                color: isForce ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapH16,
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: isForce
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.accent.withValues(alpha: 0.15),
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: isForce
                      ? AppColors.error.withValues(alpha: 0.25)
                      : AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Versi $versionName',
                style: AppTypography.caption12.copyWith(
                  color: isForce ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AppSpacing.gapH12,

          // 2. Judul
          Text(
            isForce
                ? 'Pembaruan Wajib Tersedia'
                : 'Pembaruan Aplikasi Tersedia',
            textAlign: TextAlign.center,
            style: AppTypography.title20,
          ),
          AppSpacing.gapH8,

          // 3. Deskripsi Versi
          Text(
            isForce
                ? 'Versi Timerin saat ini sudah tidak didukung. Harap perbarui ke versi $versionName agar dapat terus menggunakan aplikasi.'
                : 'Versi $versionName sudah dirilis. Dapatkan perbaikan bug, peningkatan kestabilan overlay, dan fitur-fitur terbaru.',
            textAlign: TextAlign.justify,
            style: AppTypography.body14Muted,
          ),

          // 4. Catatan Rilis (Release Notes) jika ada
          if (info.releaseNotes != null &&
              info.releaseNotes!.trim().isNotEmpty) ...<Widget>[
            AppSpacing.gapH16,
            Container(
              padding: AppSpacing.p12,
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
                        Icons.fiber_new_rounded,
                        size: 16.0,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        'Catatan Rilis:',
                        style: AppTypography.caption12.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH8,
                  Text(
                    info.releaseNotes!,
                    textAlign: TextAlign.justify,
                    style: AppTypography.caption12.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.gapH16,
          Text(
            'Unduhan resmi via web pengembang. Timerin tidak memasang APK secara otomatis demi keamanan akun Anda.',
            textAlign: TextAlign.center,
            style: AppTypography.caption12.copyWith(
              color: AppColors.textMuted,
              fontSize: 11.0,
            ),
          ),
          AppSpacing.gapH24,

          // 5. Tombol Aksi
          if (isForce)
            ElevatedButton(
              key: const Key('update_dialog_action_button'),
              onPressed: () => _handleDownload(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                elevation: 2.0,
              ),
              child: const Text(
                'Perbarui Sekarang',
                style: AppTypography.button16,
              ),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update_dialog_later_button'),
                    onPressed: () => Navigator.of(context).pop(),
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
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: ElevatedButton(
                    key: const Key('update_dialog_action_button'),
                    onPressed: () => _handleDownload(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      minimumSize: const Size.fromHeight(44.0),
                      elevation: 2.0,
                    ),
                    child: const Text(
                      'Perbarui',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final url = info.downloadUrl;
    if (url != null && url.isNotEmpty) {
      final launcher = ref.read(urlLauncherServiceProvider);
      final launched = await launcher.launchExternalUrl(url);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peramban web.')),
        );
      }
    }
  }
}
