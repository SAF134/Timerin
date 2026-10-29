import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';

/// Halaman Lengkap Kebijakan Privasi & Jaminan Keamanan Pengguna (SCR-006, UU PDP).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Kebijakan Privasi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header Badge & Intro
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
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: AppRadius.buttonRadius,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Kebijakan Privasi Aplikasi Timerin',
                            style: AppTypography.caption12.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH12,
                    const Text(
                      'Komitmen Privasi & Keamanan',
                      style: AppTypography.title20,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Timerin menghargai dan melindungi privasi serta keamanan data setiap pengguna. Dokumen ini menjelaskan secara menyeluruh dan transparan bagaimana data Anda dikelola, dilindungi, serta jaminan keamanan penuh selama Anda menggunakan aplikasi Timerin.',
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

              // 1. Keamanan Autentikasi Google
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '1. Autentikasi & Keamanan Akun Google',
                content:
                    '• Proses masuk aplikasi menggunakan otorisasi resmi Google Sign-In (OAuth 2.0).\n'
                    '• Timerin TIDAK PERNAH meminta, menerima, maupun menyimpan kata sandi (password) akun Google Anda.\n'
                    '• Informasi yang diterima terbatas pada nama tampilan, alamat email, foto profil publik, dan User ID (UID) Firebase untuk keperluan profil akun.\n'
                    '• Anda dapat keluar dari akun kapan saja secara mandiri melalui menu Pengaturan.',
              ),
              AppSpacing.gapH16,

              // 2. Integritas Game & Anti-Banned
              _buildSectionCard(
                icon: Icons.verified_user_outlined,
                title: '2. Keamanan Game & Bebas Risiko Ban (Anti-Cheat Safe)',
                content:
                    '• Timerin adalah utilitas stopwatch hitung mundur mandiri yang melayang di atas layar, terpisah sepenuhnya dari game Mobile Legends: Bang Bang.\n'
                    '• Aplikasi TIDAK membaca konten layar pengguna (tanpa screen capture/recording).\n'
                    '• Aplikasi TIDAK mengakses memori game, file instalasi game, maupun jaringan game.\n'
                    '• Aplikasi TIDAK menggunakan AccessibilityService untuk mengotomasi tindakan.\n'
                    '• Seluruh hitung mundur dijalankan murni berdasarkan ketukan manual pengguna, sehingga 100% adil, bersih, dan aman dari risiko sanksi banned.',
              ),
              AppSpacing.gapH16,

              // 3. Transparansi Izin Perangkat
              _buildSectionCard(
                icon: Icons.tune_rounded,
                title: '3. Transparansi Izin Sistem Android',
                content:
                    'Timerin hanya meminta izin sistem minimal yang mutlak dibutuhkan untuk fungsi utama:\n\n'
                    '• Tampil di Atas Aplikasi Lain (SYSTEM_ALERT_WINDOW): Menampilkan floating bubble timer di atas game.\n'
                    '• Layanan Latar Depan & Notifikasi (FOREGROUND_SERVICE & POST_NOTIFICATIONS): Menjaga timer tetap beroperasi secara akurat tanpa ditutup paksa oleh manajemen baterai sistem.\n'
                    '• Getaran Perangkat (VIBRATE): Menggetarkan perangkat selama 1 detik sebagai indikator taktil saat cooldown spell lawan selesai.',
              ),
              AppSpacing.gapH16,

              // 4. Penyimpanan Data & Privasi
              _buildSectionCard(
                icon: Icons.cloud_done_outlined,
                title: '4. Penyimpanan Data & Bebas Penjualan Data',
                content:
                    '• Seluruh data akun dan status masa aktif langganan disimpan secara terenkripsi pada server Google Firebase (Firestore).\n'
                    '• Timerin TIDAK PERNAH menjual, menyewakan, atau membagikan data pribadi Anda kepada pihak ketiga atau jaringan iklan mana pun.\n'
                    '• Aplikasi ini bebas dari pelacak iklan pihak ketiga (ad-trackers).',
              ),
              AppSpacing.gapH16,

              // 5. Hak Pengguna & Penghapusan Akun
              _buildSectionCard(
                icon: Icons.shield_outlined,
                title: '5. Hak Pengguna & Mode Privasi',
                content:
                    '• Anda memiliki hak penuh atas data akun Anda. Anda dapat menyembunyikan tampilan email dan UID pada layar dengan mengaktifkan fitur Mode Privasi di Pengaturan.\n'
                    '• Jika Anda ingin menghapus seluruh riwayat akun atau data yang tersimpan di server kami, Anda dapat mengajukan permintaan penghapusan kapan saja dengan menghubungi email pengembang.',
              ),
              AppSpacing.gapH16,

              // 6. Kontak Pengembang
              _buildSectionCard(
                icon: Icons.mail_outline_rounded,
                title: '6. Kontak Pengembang Resmi',
                content:
                    'Jika Anda memiliki pertanyaan seputar kebijakan privasi, permohonan hak data, atau kendala aktivasi langganan, silakan hubungi pengembang melalui:\n\n'
                    'Email: timerindev@gmail.com\n\n'
                    'Pembaruan Terakhir: 10 Oktober 2026',
              ),
              AppSpacing.gapH24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
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
              Icon(icon, color: AppColors.primary, size: 20.0),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title20.copyWith(fontSize: 16.0),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            content,
            style: AppTypography.body14.copyWith(
              color: AppColors.text,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
