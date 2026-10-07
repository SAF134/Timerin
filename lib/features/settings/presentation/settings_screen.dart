import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Halaman Pengaturan (SCR-006, FR-017).
///
/// Menyediakan ringkasan akun, status & tanggal berakhir langganan,
/// status izin overlay, tips baterai per merek HP, kebijakan privasi, versi,
/// dan aksi keluar / minta hapus akun.
/// Implementasi lengkap berada pada milestone T-011.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.p24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.settings_outlined,
                  size: 64.0,
                  color: AppColors.primary,
                ),
                AppSpacing.gapH16,
                Text('Pengaturan Aplikasi', style: AppTypography.title20),
                AppSpacing.gapH8,
                Text(
                  'Kelola akun, status izin, panduan baterai, dan info aplikasi.',
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
