import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/settings/presentation/support_developer_screen.dart';

/// Halaman Informasi Tentang Pengembang, Kontak, & Tautan Dukungan.
class AboutDeveloperScreen extends ConsumerWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tentang Pengembang')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Foto Pengembang (Bulat / Circular Avatar)
              Center(
                child: Container(
                  width: 160.0,
                  height: 160.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/developer.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 72.0,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH24,

              // 2. Profil & Tentang Pengembang
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: AppRadius.buttonRadius,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Pengembang Mandiri',
                            style: AppTypography.caption12.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH12,
                    const Text(
                      'Halo! Saya SAF, Pengembang Aplikasi Timerin.',
                      style: AppTypography.title20,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Aplikasi Timerin dibuat oleh saya sendiri dengan tujuan untuk mempermudah pemain game moba seperti Mobile Legends, Honor Of King, atau game moba lainnya.',
                      style: AppTypography.body14.copyWith(
                        color: AppColors.text,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // 3. Kontak Pengembang
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                        AppSpacing.gapW8,
                        Text('Kontak Pengembang', style: AppTypography.title20),
                      ],
                    ),
                    AppSpacing.gapH12,
                    Text(
                      'Jika kamu memiliki pertanyaan, kendala verifikasi langganan, atau masukan untuk pengembangan Timerin, silakan hubungi:',
                      style: AppTypography.body14.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    AppSpacing.gapH12,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('developer_email_button'),
                        onPressed: () {
                          ref
                              .read(urlLauncherServiceProvider)
                              .launchEmail(
                                recipient: 'timerindev@gmail.com',
                                subject: 'Tanya Pengembang Timerin',
                                body: 'Halo Pengembang Timerin,\n\n',
                              );
                        },
                        icon: const Icon(Icons.email_rounded, size: 18.0),
                        label: const Text('timerindev@gmail.com'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          minimumSize: const Size.fromHeight(48.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          elevation: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // 4. Unduh Aplikasi & Website Resmi
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.language_rounded,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'Website Resmi & Unduhan',
                          style: AppTypography.title20,
                        ),
                      ],
                    ),
                    AppSpacing.gapH12,
                    Text(
                      'Unduh versi APK terbaru Timerin, baca panduan fitur, serta bagikan tautan resmi aplikasi kepada teman mabar Anda melalui website resmi:',
                      style: AppTypography.body14.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    AppSpacing.gapH12,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('developer_website_button'),
                        onPressed: () {
                          ref
                              .read(urlLauncherServiceProvider)
                              .launchExternalUrl('https://timerin.vercel.app/');
                        },
                        icon: const Icon(
                          Icons.open_in_browser_rounded,
                          size: 18.0,
                        ),
                        label: const Text('timerin.vercel.app'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          minimumSize: const Size.fromHeight(48.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          elevation: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // 5. Dukungan untuk Pengembang (Navigasi ke SupportDeveloperScreen)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          color: AppColors.primary,
                          size: 20.0,
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
                      'Jika aplikasi ini bermanfaat bagi gameplay kamu, dukungan tip/donasi sukarela melalui QRIS sangat membantu biaya server Firebase dan pemeliharaan fitur berkelanjutan.',
                      style: AppTypography.body14.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    AppSpacing.gapH16,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('open_support_developer_button'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SupportDeveloperScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18.0),
                        label: const Text('Buka Barcode QRIS Dukungan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          minimumSize: const Size.fromHeight(44.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          elevation: 2.0,
                        ),
                      ),
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
