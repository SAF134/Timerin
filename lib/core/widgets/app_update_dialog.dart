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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      contentPadding: AppSpacing.p24,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Icon Header
          Center(
            child: Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: isForce
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isForce
                    ? Icons.system_update_rounded
                    : Icons.new_releases_rounded,
                size: 28.0,
                color: isForce ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapH16,

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
            'Versi $versionName sudah dirilis. '
            '${isForce ? "Versi yang Anda gunakan saat ini sudah tidak didukung. Harap perbarui untuk melanjutkan." : "Perbarui aplikasi untuk mendapatkan peningkatan performa dan perbaikan terbaru."}',
            textAlign: TextAlign.center,
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
                  Text(
                    'Apa yang Baru:',
                    style: AppTypography.caption12.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    info.releaseNotes!,
                    style: AppTypography.caption12.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.gapH16,
          const Text(
            'Unduhan resmi via tautan resmi. Timerin tidak memasang APK secara otomatis demi keamanan.',
            textAlign: TextAlign.center,
            style: AppTypography.caption12,
          ),
          AppSpacing.gapH24,

          // 5. Tombol Aksi Utama (Unduh / Perbarui)
          ElevatedButton(
            key: const Key('update_dialog_action_button'),
            onPressed: () async {
              final url = info.downloadUrl;
              if (url != null && url.isNotEmpty) {
                final launcher = ref.read(urlLauncherServiceProvider);
                final launched = await launcher.launchExternalUrl(url);
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak dapat membuka peramban web.'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: const Text(
              'Perbarui Sekarang',
              style: AppTypography.button16,
            ),
          ),

          // 6. Tombol Aksi Opsional (Nanti Saja)
          if (!isForce) ...<Widget>[
            AppSpacing.gapH8,
            TextButton(
              key: const Key('update_dialog_later_button'),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text('Nanti Saja'),
            ),
          ],
        ],
      ),
    );
  }
}
