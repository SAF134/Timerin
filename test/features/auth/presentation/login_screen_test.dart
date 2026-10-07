import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

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
      child: MaterialApp(theme: AppTheme.theme, home: const LoginScreen()),
    );
  }

  group('LoginScreen Tests (SCR-003 / FR-003)', () {
    testWidgets('renders Google sign-in button and privacy policy note', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidgetUnderTest(prefs));

      expect(find.text('Masuk ke Timerin'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(
        find.text('Dengan masuk, kamu menyetujui Kebijakan Privasi Timerin.'),
        findsOneWidget,
      );
    });

    testWidgets('successful Google sign-in navigates to HomeScreen', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.displayName).thenReturn('Gamer');
      when(() => mockUser.email).thenReturn('gamer@example.com');
      when(() => mockAuthService.currentUser).thenReturn(mockUser);
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenAnswer((_) async => mockCredential);

      await tester.pumpWidget(createWidgetUnderTest(prefs));

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signInWithGoogle()).called(1);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('failed Google sign-in shows error SnackBar with retry', (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidgetUnderTest(prefs));

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Gagal masuk dengan Google. Silakan coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
