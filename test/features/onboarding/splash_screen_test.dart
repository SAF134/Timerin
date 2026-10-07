import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';
import 'package:timerin/features/onboarding/presentation/onboarding_screen.dart';
import 'package:timerin/features/onboarding/presentation/splash_screen.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  late MockAuthService mockAuthService;
  late MockAppUpdateService mockUpdateService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUpdateService = MockAppUpdateService();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    when(() => mockUpdateService.checkUpdate()).thenAnswer(
      (_) async => const AppUpdateInfo(
        type: AppUpdateType.upToDate,
        currentVersionCode: 1,
        currentVersionName: '1.0.0',
      ),
    );
  });

  Widget createWidgetUnderTest({
    required SharedPreferences prefs,
    User? currentUser,
    AppUpdateInfo? updateInfo,
  }) {
    when(() => mockAuthService.currentUser).thenReturn(currentUser);
    if (updateInfo != null) {
      when(
        () => mockUpdateService.checkUpdate(),
      ).thenAnswer((_) async => updateInfo);
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuthService),
        appUpdateServiceProvider.overrideWithValue(mockUpdateService),
      ],
      child: MaterialApp(
        theme: AppTheme.theme,
        home: const SplashScreen(duration: Duration(milliseconds: 50)),
      ),
    );
  }

  group('SplashScreen Navigation Tests (SCR-001 / FR-001)', () {
    testWidgets('renders Timerin logo and branding', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidgetUnderTest(prefs: prefs));

      expect(find.text('Timerin'), findsOneWidget);
      expect(find.text('Smart Spell Cooldown Overlay'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('routes to HomeScreen when user is already logged in', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final mockUser = MockUser();
      when(() => mockUser.displayName).thenReturn('ProPlayer');
      when(() => mockUser.email).thenReturn('pro@example.com');

      await tester.pumpWidget(
        createWidgetUnderTest(prefs: prefs, currentUser: mockUser),
      );

      // Fast forward past splash duration
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'routes to OnboardingScreen when not logged in and has not seen onboarding',
      (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', false);

        await tester.pumpWidget(createWidgetUnderTest(prefs: prefs));

        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'routes to LoginScreen when not logged in but has already seen onboarding',
      (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);

        await tester.pumpWidget(createWidgetUnderTest(prefs: prefs));

        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'shows force update dialog and halts navigation when force update required',
      (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();
        const forceUpdateInfo = AppUpdateInfo(
          type: AppUpdateType.force,
          currentVersionCode: 1,
          currentVersionName: '1.0.0',
          latestVersionCode: 3,
          latestVersionName: '1.2.0',
          minVersionCode: 2,
          downloadUrl: 'https://drive.google.com/apk-v3',
          releaseNotes: 'Pembaruan wajib.',
        );

        await tester.pumpWidget(
          createWidgetUnderTest(prefs: prefs, updateInfo: forceUpdateInfo),
        );

        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();

        expect(find.text('Pembaruan Wajib Tersedia'), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );
  });
}
