import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockOverlayPermissionService extends Mock
    implements OverlayPermissionService {}

class MockOverlayServiceController extends Mock
    implements OverlayServiceController {}

class FakeAccessNotifier extends AccessNotifier {
  FakeAccessNotifier(this._initialState);

  final AccessState _initialState;
  bool startTrialCalled = false;

  @override
  AccessState build() => _initialState;

  @override
  Future<void> refreshAccess() async {}

  @override
  Future<bool> startTrial() async {
    startTrialCalled = true;
    state = const AccessState(
      status: AccessStatus.trial,
      remainingAccess: Duration(hours: 24),
    );
    return true;
  }
}

void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockOverlayPermissionService mockPermissionService;
  late MockOverlayServiceController mockOverlayController;
  late SharedPreferences prefs;

  const testUserModel = UserModel(
    uid: 'test_uid',
    email: 'raka@example.com',
    displayName: 'Raka MLBB',
  );

  setUp(() async {
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockPermissionService = MockOverlayPermissionService();
    mockOverlayController = MockOverlayServiceController();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();

    registerFallbackValue(const TimerSettings());
    when(() => mockUser.displayName).thenReturn('Raka MLBB');
    when(() => mockUser.email).thenReturn('raka@example.com');
    when(() => mockAuthService.currentUser).thenReturn(mockUser);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest({
    AccessState accessState = const AccessState(
      status: AccessStatus.trial,
      remainingAccess: Duration(hours: 20),
    ),
    FakeAccessNotifier? customNotifier,
  }) {
    final notifier = customNotifier ?? FakeAccessNotifier(accessState);

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuthService),
        currentUserModelProvider.overrideWith(
          (ref) => Stream.value(testUserModel),
        ),
        overlayPermissionServiceProvider.overrideWithValue(
          mockPermissionService,
        ),
        overlayServiceControllerProvider.overrideWithValue(
          mockOverlayController,
        ),
        accessStateProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp(theme: AppTheme.theme, home: const HomeScreen()),
    );
  }

  group('HomeScreen Tests (T-005, T-007, T-009 / FR-004, FR-010, FR-013, FR-014)', () {
    testWidgets(
      'renders user card, access banner, and overlay control card with inactive status',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('Selamat Datang,'), findsOneWidget);
        expect(find.text('Raka MLBB'), findsOneWidget);
        expect(find.text('raka@example.com'), findsOneWidget);
        expect(find.text('sisa 20 jam'), findsOneWidget);
        expect(find.text('Overlay Spell'), findsOneWidget);
        expect(find.text('Status: Nonaktif'), findsOneWidget);
        expect(find.byKey(const Key('start_overlay_button')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Aktifkan Overlay when permission not granted opens OverlayPermissionDialog',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_overlay_button')));
        await tester.pumpAndSettle();

        expect(find.byType(OverlayPermissionDialog), findsOneWidget);
        verify(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).called(1);
        verifyNever(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        );
      },
    );

    testWidgets(
      'tapping Aktifkan Overlay when status is BARU starts trial atomically before overlay (FR-013)',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => true);
        when(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async => true);

        final notifier = FakeAccessNotifier(
          const AccessState(
            status: AccessStatus.baru,
            remainingAccess: Duration.zero,
          ),
        );

        await tester.pumpWidget(
          createWidgetUnderTest(customNotifier: notifier),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_overlay_button')));
        await tester.pumpAndSettle();

        expect(notifier.startTrialCalled, isTrue);
        verify(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        ).called(1);
        expect(find.text('Status: Aktif'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Aktifkan Overlay when status is HABIS prevents launch and shows snackbar (FR-014)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            accessState: const AccessState(
              status: AccessStatus.habis,
              remainingAccess: Duration.zero,
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_overlay_button')));
        await tester.pumpAndSettle();

        verifyNever(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        );
        expect(
          find.text('Masa aktif telah habis. Silakan berlangganan.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Aktifkan Overlay when permission granted calls startOverlay and activates status',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => true);
        when(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_overlay_button')));
        await tester.pumpAndSettle();

        verify(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        ).called(1);
        expect(find.text('Status: Aktif'), findsOneWidget);
        expect(find.byKey(const Key('stop_overlay_button')), findsOneWidget);
        expect(find.text('Overlay spell telah diaktifkan.'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Matikan Overlay calls stopOverlay and reverts status to inactive',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => true);
        when(
          () => mockOverlayController.startOverlay(
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockOverlayController.stopOverlay(),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // 1. Activate
        await tester.tap(find.byKey(const Key('start_overlay_button')));
        await tester.pumpAndSettle();
        expect(find.text('Status: Aktif'), findsOneWidget);

        // 2. Deactivate
        await tester.tap(find.byKey(const Key('stop_overlay_button')));
        await tester.pumpAndSettle();

        verify(() => mockOverlayController.stopOverlay()).called(1);
        expect(find.text('Status: Nonaktif'), findsOneWidget);
        expect(find.byKey(const Key('start_overlay_button')), findsOneWidget);
        expect(find.text('Overlay dinonaktifkan.'), findsOneWidget);
      },
    );

    testWidgets('tapping Keluar calls signOut and navigates to LoginScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.ensureVisible(find.text('Keluar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signOut()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
