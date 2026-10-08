import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';
import 'package:timerin/features/onboarding/presentation/onboarding_screen.dart';

/// SCR-003 Masuk: Login dengan Google dan persetujuan Kebijakan Privasi.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential != null && mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal masuk dengan Google. Silakan coba lagi.'),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: AppColors.warning,
            onPressed: _handleGoogleSignIn,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text(
            'Kebijakan Privasi Timerin',
            style: AppTypography.title20,
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Timerin berkomitmen penuh menjaga privasi dan keamanan data Anda sesuai dengan UU Perlindungan Data Pribadi (UU PDP).',
                  style: AppTypography.body14,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH12,
                Text(
                  '1. Keamanan Akun Google\nProses autentikasi menggunakan Google Sign-In resmi. Aplikasi hanya menerima nama, email, UID, dan foto profil. Aplikasi tidak pernah memiliki akses ke kata sandi akun Google Anda.',
                  style: AppTypography.body14,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH12,
                Text(
                  '2. Tanpa Akses Layar & Data Game\nTimerin adalah overlay timer utilitas independen. Aplikasi tidak membaca layar game, memori game, atau aktivitas aplikasi lain di ponsel.',
                  style: AppTypography.body14,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH12,
                Text(
                  '3. Penggunaan Data\nData akun semata-mata digunakan untuk identitas profil dan pencatatan masa aktif langganan Anda secara aman di server Firebase.',
                  style: AppTypography.body14,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header Hero Section (Midnight Navy)
            Expanded(
              child: Center(
                child: Padding(
                  padding: AppSpacing.h24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/timerin.png',
                        width: 96.0,
                        height: 96.0,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 90.0,
                          height: 90.0,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.cardRadius,
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            size: 52.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      AppSpacing.gapH24,
                      Text(
                        'Masuk ke Timerin',
                        style: AppTypography.display28.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      AppSpacing.gapH8,
                      Text(
                        'Hitung spell musuh dengan mudah dan raih kemenangan.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body14.copyWith(
                          color: AppColors.textMutedHeader,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom White Card Section
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sheetRadius,
              ),
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Jaminan Keamanan & Privasi Akun
                  Container(
                    padding: AppSpacing.p12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.buttonRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 18.0,
                              color: AppColors.accent,
                            ),
                            AppSpacing.gapW8,
                            Text(
                              'Jaminan Keamanan Akun & Privasi',
                              style: AppTypography.caption12.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH4,
                        Text(
                          '• Masuk Google resmi & terenkripsi: akun aman dan kata sandi Anda tidak dapat diakses aplikasi.\n• Timerin 100% aman: tidak membaca layar game, pesan, atau data sensitif di HP Anda.\n• Data hanya untuk identitas profil & masa aktif langganan.',
                          style: AppTypography.caption12.copyWith(
                            color: AppColors.text,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Google Sign-In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.g_mobiledata,
                                size: 30.0,
                                color: AppColors.primary,
                              ),
                              AppSpacing.gapW8,
                              Text(
                                'Masuk dengan Google',
                                style: AppTypography.button16.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  AppSpacing.gapH12,

                  // Tombol Akses Panduan / Onboarding Aplikasi
                  OutlinedButton.icon(
                    key: const Key('view_onboarding_button'),
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const OnboardingScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.help_outline_rounded, size: 18.0),
                    label: const Text('Halaman Panduan & Fitur'),
                  ),
                  AppSpacing.gapH12,

                  // Privacy Policy Notice & Dialog Trigger
                  GestureDetector(
                    key: const Key('login_privacy_policy_link'),
                    onTap: _showPrivacyPolicyDialog,
                    child: Text(
                      'Dengan masuk, kamu menyetujui Kebijakan Privasi Timerin.\n(Ketuk untuk membaca ringkasan privasi lengkap)',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
