import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/core/widgets/app_update_dialog.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';
import 'package:timerin/features/onboarding/presentation/onboarding_screen.dart';

/// SCR-001 Splash Screen: logo + nama di tengah, otomatis mengarahkan rute (maks. 1.5 dtk).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Duration duration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRoutingTimer();
  }

  void _startRoutingTimer() {
    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    // 1. Cek pembaruan wajib (force update) sebelum routing
    final updateService = ref.read(appUpdateServiceProvider);
    final updateInfo = await updateService.checkUpdate();
    if (updateInfo.isForceUpdate && mounted) {
      await AppUpdateDialog.show(context, updateInfo);
      return;
    }

    final authUser = ref.read(authServiceProvider).currentUser;
    final hasSeenOnboarding = ref
        .read(onboardingRepositoryProvider)
        .hasSeenOnboarding();

    Widget targetScreen;
    if (authUser != null) {
      targetScreen = const HomeScreen();
    } else if (!hasSeenOnboarding) {
      targetScreen = const OnboardingScreen();
    } else {
      targetScreen = const LoginScreen();
    }

    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => targetScreen));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 80.0,
              height: 80.0,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.cardRadius,
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 44.0,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              'Timerin',
              style: AppTypography.display28.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'Smart Spell Cooldown Overlay',
              style: AppTypography.body14.copyWith(
                color: AppColors.textMutedHeader,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
