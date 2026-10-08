import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Halaman Informasi Tentang Pengembang, Kontak, & Dukungan QRIS.
class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tentang Pengembang')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Foto Pengembang (1:1 Ratio)
              Center(
                child: Container(
                  width: 180.0,
                  height: 180.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
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
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 1.0,
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
                      'Halo! Saya pengembang aplikasi Timerin.',
                      style: AppTypography.title20,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Timerin dirancang dan dikembangkan secara mandiri untuk memberikan utilitas stopwatch/countdown cooldown battle spell yang adil, bersih, dan praktis bagi komunitas pemain Mobile Legends: Bang Bang di Indonesia.',
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
                    AppSpacing.gapH8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.buttonRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.email_rounded,
                            size: 18.0,
                            color: AppColors.primary,
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: SelectableText(
                              'timerindev@gmail.com',
                              style: AppTypography.body14.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // 4. Dukungan untuk Pengembang (QRIS)
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
                      'Jika aplikasi ini bermanfaat bagi gameplay kamu, dukungan tip/donasi sukarela sangat membantu biaya server Firebase dan pembaruan fitur:',
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
