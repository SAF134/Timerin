import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';

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
                      Container(
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
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
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
                  AppSpacing.gapH16,

                  // Privacy Policy Notice
                  Text(
                    'Dengan masuk, kamu menyetujui Kebijakan Privasi Timerin.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption12.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
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
