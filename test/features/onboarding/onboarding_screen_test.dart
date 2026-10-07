import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/onboarding/presentation/onboarding_screen.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget createWidgetUnderTest(SharedPreferences prefs) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
      child: MaterialApp(theme: AppTheme.theme, home: const OnboardingScreen()),
    );
  }

  group('OnboardingScreen Tests (SCR-002 / FR-002)', () {
    testWidgets('renders first slide with title and navigation buttons', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidgetUnderTest(prefs));

      expect(find.text('Hitung Cooldown Seketika'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets(
      'tapping Lanjut navigates to second slide (Overlay permission)',
      (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidgetUnderTest(prefs));

        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();

        expect(find.text('Izin Tampil di Atas Aplikasi'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Lewati marks onboarding complete and navigates to LoginScreen',
      (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidgetUnderTest(prefs));

        await tester.tap(find.text('Lewati'));
        await tester.pumpAndSettle();

        expect(prefs.getBool('has_seen_onboarding'), isTrue);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
