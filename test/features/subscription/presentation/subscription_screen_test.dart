import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/constants/app_constants.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

class FakeAccessNotifier extends AccessNotifier {
  FakeAccessNotifier(this._initialState);

  final AccessState _initialState;
  bool refreshAccessCalled = false;

  @override
  AccessState build() => _initialState;

  @override
  Future<void> refreshAccess() async {
    refreshAccessCalled = true;
  }
}

void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockUrlLauncherService mockLauncherService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockLauncherService = MockUrlLauncherService();

    when(() => mockUser.uid).thenReturn('user_123_abc');
    when(() => mockUser.email).thenReturn('gamer@example.com');
    when(() => mockAuthService.currentUser).thenReturn(mockUser);
  });

  Widget createWidgetUnderTest({
    AccessState accessState = const AccessState(
      status: AccessStatus.habis,
      remainingAccess: Duration.zero,
    ),
    FakeAccessNotifier? customNotifier,
  }) {
    final notifier = customNotifier ?? FakeAccessNotifier(accessState);

    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        urlLauncherServiceProvider.overrideWithValue(mockLauncherService),
        accessStateProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.theme,
        home: const SubscriptionScreen(),
      ),
    );
  }

  group('SubscriptionScreen Tests (SCR-005, FR-015, FR-016)', () {
    testWidgets('renders pricing, QRIS card, steps, and user details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Berlangganan'), findsOneWidget);
      expect(find.text('Rp10.000'), findsOneWidget);
      expect(find.text('/ 30 hari'), findsOneWidget);
      expect(find.text('QRIS Pembayaran Statis'), findsOneWidget);
      expect(find.text('Langkah Pembayaran'), findsOneWidget);
      expect(find.text('gamer@example.com'), findsOneWidget);
      expect(find.text('UID: user_123_abc'), findsOneWidget);
      expect(find.byKey(const Key('send_proof_email_button')), findsOneWidget);
      expect(find.byKey(const Key('refresh_status_button')), findsOneWidget);
    });

    testWidgets(
      'tapping Kirim Bukti via Email calls launchEmail with UID and email template (FR-015)',
      (WidgetTester tester) async {
        when(
          () => mockLauncherService.launchEmail(
            recipient: any(named: 'recipient'),
            subject: any(named: 'subject'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        final sendEmailBtn = find.byKey(const Key('send_proof_email_button'));
        await tester.ensureVisible(sendEmailBtn);
        await tester.pumpAndSettle();
        await tester.tap(sendEmailBtn);
        await tester.pumpAndSettle();

        verify(
          () => mockLauncherService.launchEmail(
            recipient: AppConstants.developerSupportEmail,
            subject: any(named: 'subject', that: contains('user_123_abc')),
            body: any(
              named: 'body',
              that: allOf(
                contains('user_123_abc'),
                contains('gamer@example.com'),
                contains('Rp10.000'),
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('shows fallback alert dialog when launchEmail returns false', (
      WidgetTester tester,
    ) async {
      when(
        () => mockLauncherService.launchEmail(
          recipient: any(named: 'recipient'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final sendEmailBtn = find.byKey(const Key('send_proof_email_button'));
      await tester.ensureVisible(sendEmailBtn);
      await tester.pumpAndSettle();
      await tester.tap(sendEmailBtn);
      await tester.pumpAndSettle();

      expect(find.text('Aplikasi Email Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Salin Informasi'), findsOneWidget);

      await tester.tap(find.text('Salin Informasi'));
      await tester.pumpAndSettle();

      expect(find.text('Detail email disalin ke clipboard.'), findsOneWidget);
    });

    testWidgets(
      'tapping Segarkan Status calls refreshAccess and shows snackbar (FR-016)',
      (WidgetTester tester) async {
        final notifier = FakeAccessNotifier(
          const AccessState(
            status: AccessStatus.berlangganan,
            remainingAccess: Duration(days: 30),
          ),
        );

        await tester.pumpWidget(
          createWidgetUnderTest(customNotifier: notifier),
        );
        await tester.pump();

        final refreshBtn = find.byKey(const Key('refresh_status_button'));
        await tester.ensureVisible(refreshBtn);
        await tester.pumpAndSettle();
        await tester.tap(refreshBtn);
        await tester.pumpAndSettle();

        expect(notifier.refreshAccessCalled, isTrue);
        expect(
          find.text('Status akses disinkronkan: sisa 30 hari'),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping copy nominal button copies and shows snackbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final copyBtn = find.byKey(const Key('copy_nominal_button'));
      await tester.ensureVisible(copyBtn);
      await tester.pumpAndSettle();
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Nominal Rp10.000 disalin ke clipboard.'),
        findsOneWidget,
      );
    });
  });
}
