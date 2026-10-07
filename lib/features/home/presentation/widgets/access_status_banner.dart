import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';

/// Banner status akses pengguna di Beranda (SCR-004, FR-004, FR-014).
///
/// Menampilkan 4 kondisi akses:
/// 1. [AccessStatus.baru]: Penjelasan trial 24 jam siap dimulai saat aktivasi pertama.
/// 2. [AccessStatus.trial]: Sisa jam trial berjalan dan tautan berlangganan.
/// 3. [AccessStatus.berlangganan]: Masa aktif langganan dan status terverifikasi.
/// 4. [AccessStatus.habis]: Peringatan masa aktif selesai dan ajakan berlangganan Rp10.000/bln.
class AccessStatusBanner extends StatelessWidget {
  const AccessStatusBanner({
    super.key,
    required this.accessState,
    this.onSubscribePressed,
  });

  final AccessState accessState;
  final VoidCallback? onSubscribePressed;

  @override
  Widget build(BuildContext context) {
    switch (accessState.status) {
      case AccessStatus.baru:
        return _buildBaruBanner();
      case AccessStatus.trial:
        return _buildTrialBanner();
      case AccessStatus.berlangganan:
        return _buildBerlanggananBanner();
      case AccessStatus.habis:
        return _buildHabisBanner();
    }
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required String description,
    required Color borderColor,
    Widget? action,
  }) {
    return Container(
      key: const Key('access_status_banner'),
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 24.0),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body16Medium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: Text(
                  badgeText,
                  style: AppTypography.caption12.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          Text(description, style: AppTypography.body14Muted),
          if (action != null) ...<Widget>[AppSpacing.gapH12, action],
        ],
      ),
    );
  }

  Widget _buildBaruBanner() {
    return _buildCard(
      icon: Icons.stars_rounded,
      iconColor: AppColors.accent,
      title: 'Trial 24 Jam',
      badgeText: 'Siap Dimulai',
      badgeBg: AppColors.surfaceVariant,
      badgeTextColor: AppColors.textMuted,
      description:
          'Trial 24 jam gratis siap dimulai saat kamu mengaktifkan overlay pertama kali.',
      borderColor: AppColors.border,
    );
  }

  Widget _buildTrialBanner() {
    return _buildCard(
      icon: Icons.timer_outlined,
      iconColor: AppColors.accent,
      title: 'Masa Coba Gratis',
      badgeText: accessState.remainingFormatted,
      badgeBg: AppColors.accent.withValues(alpha: 0.1),
      badgeTextColor: AppColors.primary,
      description:
          'Masa coba gratis sedang aktif (${accessState.remainingFormatted}). Akses penuh seluruh fitur overlay.',
      borderColor: AppColors.accent.withValues(alpha: 0.5),
      action: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('banner_subscribe_button'),
          onPressed: onSubscribePressed,
          icon: const Icon(Icons.bolt_rounded, size: 16.0),
          label: const Text('Berlangganan Rp10.000/bln'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBerlanggananBanner() {
    return _buildCard(
      icon: Icons.verified_rounded,
      iconColor: AppColors.accent,
      title: 'Status Berlangganan',
      badgeText: 'Aktif (${accessState.remainingFormatted})',
      badgeBg: AppColors.accent.withValues(alpha: 0.1),
      badgeTextColor: AppColors.primary,
      description:
          'Status Berlangganan: Aktif (${accessState.remainingFormatted}). Terima kasih telah mendukung Timerin!',
      borderColor: AppColors.accent.withValues(alpha: 0.6),
    );
  }

  Widget _buildHabisBanner() {
    return _buildCard(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.error,
      title: 'Masa Aktif Selesai',
      badgeText: 'Habis',
      badgeBg: AppColors.error.withValues(alpha: 0.1),
      badgeTextColor: AppColors.error,
      description:
          'Trial 24 jam selesai. Berlangganan Rp10.000/bulan untuk lanjut memakai timer.',
      borderColor: AppColors.error.withValues(alpha: 0.7),
      action: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('banner_subscribe_button'),
          onPressed: onSubscribePressed,
          icon: const Icon(Icons.shopping_bag_outlined, size: 18.0),
          label: const Text('Berlangganan Sekarang'),
        ),
      ),
    );
  }
}
