import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Halaman Berlangganan (SCR-005, FR-015, FR-016).
///
/// Menyediakan QRIS statis Rp10.000 / 30 hari, panduan pembayaran,
/// pengiriman bukti via email otomatis, dan tombol segarkan status akses.
/// Implementasi lengkap berada pada milestone T-010.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Berlangganan')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.p24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 64.0,
                  color: AppColors.primary,
                ),
                AppSpacing.gapH16,
                Text('Halaman Berlangganan', style: AppTypography.title20),
                AppSpacing.gapH8,
                Text(
                  'Aktivasi langganan Rp10.000 / 30 hari via QRIS.',
                  style: AppTypography.body14Muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
