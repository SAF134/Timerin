import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/qris_share_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Halaman Dukung Pengembang melalui donasi/tip sukarela QRIS.
class SupportDeveloperScreen extends ConsumerWidget {
  const SupportDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Dukung Pengembang')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          color: AppColors.primary,
                          size: 22.0,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'Dukung Pengembang',
                          style: AppTypography.title20.copyWith(fontSize: 18.0),
                        ),
                      ],
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Jika aplikasi ini bermanfaat bagi gameplay kamu, dukungan tip/donasi sukarela sangat membantu biaya server Firebase dan pemeliharaan fitur berkelanjutan:',
                      textAlign: TextAlign.justify,
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.gapH16,
                    Container(
                      width: 280.0,
                      height: 280.0,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 14.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/qris.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 80.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapH16,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton.icon(
                          key: const Key('save_qris_developer_button'),
                          onPressed: () async {
                            final shareService = ref.read(
                              qrisShareServiceProvider,
                            );
                            final success = await shareService
                                .saveQrisToGallery();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Barcode QRIS berhasil disimpan ke galeri perangkat!'
                                        : 'Tidak dapat menyimpan gambar ke galeri.',
                                  ),
                                ),
                              );
                          },
                          icon: const Icon(Icons.download_rounded, size: 14.0),
                          label: const Text(
                            'Simpan QRIS',
                            style: TextStyle(fontSize: 12.0),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonRadius,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            minimumSize: const Size(0, 32.0),
                          ),
                        ),
                        AppSpacing.gapW8,
                        ElevatedButton.icon(
                          key: const Key('share_qris_developer_button'),
                          onPressed: () async {
                            final shareService = ref.read(
                              qrisShareServiceProvider,
                            );
                            final success = await shareService.shareQris();
                            if (!context.mounted) return;
                            if (!success) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tidak dapat membuka lembar berbagi sistem.',
                                    ),
                                  ),
                                );
                            }
                          },
                          icon: const Icon(Icons.share_rounded, size: 14.0),
                          label: const Text(
                            'Bagikan QRIS',
                            style: TextStyle(fontSize: 12.0),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonRadius,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            minimumSize: const Size(0, 32.0),
                            elevation: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
