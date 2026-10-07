import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// SCR-002 Onboarding (3 slide)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingItem> _slides = <OnboardingItem>[
    OnboardingItem(
      icon: Icons.touch_app_outlined,
      title: 'Hitung Cooldown Seketika',
      description:
          'Catat waktu cooldown spell musuh dengan satu ketukan tanpa harus keluar dari pertandingan Mobile Legends.',
    ),
    OnboardingItem(
      icon: Icons.layers_outlined,
      title: 'Izin Tampil di Atas Aplikasi',
      description:
          'Timerin hanya butuh izin overlay untuk menampilkan widget floating timer. Kami tidak membaca layar atau data game kamu.',
    ),
    OnboardingItem(
      icon: Icons.card_giftcard_outlined,
      title: 'Coba Gratis 24 Jam',
      description:
          'Trial gratis otomatis mulai saat overlay pertama kali kamu aktifkan. Setelah itu, langganan terjangkau Rp10.000/bulan.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingRepositoryProvider).setHasSeenOnboarding(true);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _nextPage() async {
    if (_currentPage < _slides.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Bar: Skip button on slides 0 & 1
            Padding(
              padding: AppSpacing.p16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Lewati',
                        style: AppTypography.body14.copyWith(
                          color: AppColors.textMutedHeader,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48.0),
                ],
              ),
            ),

            // Illustration / Icon area
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (BuildContext context, int index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: AppSpacing.h24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 140.0,
                          height: 140.0,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64.0,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        AppSpacing.gapH32,
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.display28.copyWith(
                            color: AppColors.textOnPrimary,
                            fontSize: 24.0,
                          ),
                        ),
                        AppSpacing.gapH16,
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.body14.copyWith(
                            color: AppColors.textMutedHeader,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom White Card Sheet
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sheetRadius,
              ),
              padding: const EdgeInsets.fromLTRB(24.0, 28.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Dot Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      _slides.length,
                      (int i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == i ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Action Buttons
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Mulai Sekarang'
                          : 'Lanjut',
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
