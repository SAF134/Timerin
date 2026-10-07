import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/home/presentation/home_screen.dart';
import 'package:timerin/features/home/presentation/widgets/access_status_banner.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/settings/presentation/settings_screen.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockOverlayPermissionService extends Mock
    implements OverlayPermissionService {}

class MockOverlayServiceController extends Mock
    implements OverlayServiceController {}

class MockAppUpdateService extends Mock implements AppUpdateService {}

class FakeAccessNotifier extends AccessNotifier {
  FakeAccessNotifier(this._initialState);

  final AccessState _initialState;
  bool startTrialCalled = false;
  bool refreshAccessCalled = false;

  @override
  AccessState build() => _initialState;

  @override
  Future<void> refreshAccess() async {
    refreshAccessCalled = true;
  }

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
  late MockAppUpdateService mockUpdateService;
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
    mockUpdateService = MockAppUpdateService();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();

    registerFallbackValue(const TimerSettings());
    when(() => mockUser.uid).thenReturn('test_uid');
    when(() => mockUser.displayName).thenReturn('Raka MLBB');
    when(() => mockUser.email).thenReturn('raka@example.com');
    when(() => mockAuthService.currentUser).thenReturn(mockUser);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
    when(
      () => mockPermissionService.isOverlayPermissionGranted(),
    ).thenAnswer((_) async => true);
    when(() => mockUpdateService.checkUpdate()).thenAnswer(
      (_) async => const AppUpdateInfo(
        type: AppUpdateType.upToDate,
        currentVersionCode: 1,
        currentVersionName: '1.0.0',
      ),
    );
  });

  Widget createWidgetUnderTest({
    AccessState accessState = const AccessState(
      status: AccessStatus.trial,
      remainingAccess: Duration(hours: 20),
    ),
    FakeAccessNotifier? customNotifier,
    AppUpdateInfo? updateInfo,
  }) {
    final notifier = customNotifier ?? FakeAccessNotifier(accessState);
    if (updateInfo != null) {
      when(
        () => mockUpdateService.checkUpdate(),
      ).thenAnswer((_) async => updateInfo);
    }

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
        appUpdateServiceProvider.overrideWithValue(mockUpdateService),
        accessStateProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp(theme: AppTheme.theme, home: const HomeScreen()),
    );
  }

  group(
    'HomeScreen Tests (T-004, T-005, T-007, T-008, T-009 / FR-004, FR-010, FR-013, FR-014, FR-016)',
    () {
      testWidgets(
        'renders user card, access banner, and overlay control card with inactive status',
        (WidgetTester tester) async {
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pump();

          expect(find.text('Selamat Datang,'), findsOneWidget);
          expect(find.text('Raka MLBB'), findsOneWidget);
          expect(find.text('raka@example.com'), findsOneWidget);
          expect(find.byType(AccessStatusBanner), findsOneWidget);
          expect(find.text('Overlay Spell'), findsOneWidget);
          expect(find.text('Status: Nonaktif'), findsOneWidget);
          expect(find.byKey(const Key('start_overlay_button')), findsOneWidget);
        },
      );

      testWidgets(
        'pull-to-refresh triggers refreshAccess on accessStateProvider (FR-016)',
        (WidgetTester tester) async {
          final notifier = FakeAccessNotifier(
            const AccessState(
              status: AccessStatus.trial,
              remainingAccess: Duration(hours: 15),
            ),
          );

          await tester.pumpWidget(
            createWidgetUnderTest(customNotifier: notifier),
          );
          await tester.pump();

          // Reset flag from initial build
          notifier.refreshAccessCalled = false;

          await tester.fling(
            find.byType(SingleChildScrollView),
            const Offset(0.0, 300.0),
            1000.0,
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();

          expect(notifier.refreshAccessCalled, isTrue);
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

          final startBtn = find.byKey(const Key('start_overlay_button'));
          await tester.ensureVisible(startBtn);
          await tester.pumpAndSettle();
          await tester.tap(startBtn);
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

          final startBtn = find.byKey(const Key('start_overlay_button'));
          await tester.ensureVisible(startBtn);
          await tester.pumpAndSettle();
          await tester.tap(startBtn);
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
        'when status is HABIS, Aktifkan Overlay button is disabled and warning caption is shown (FR-014)',
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

          final button = tester.widget<ElevatedButton>(
            find.byKey(const Key('start_overlay_button')),
          );
          expect(button.onPressed, isNull);

          expect(
            find.text(
              'Tombol overlay dinonaktifkan karena masa akses telah selesai.',
            ),
            findsOneWidget,
          );
          expect(find.text('Masa Aktif Selesai'), findsOneWidget);

          verifyNever(
            () => mockOverlayController.startOverlay(
              settings: any(named: 'settings'),
            ),
          );
        },
      );

      testWidgets(
        'tapping banner subscribe button opens SubscriptionScreen (SCR-005)',
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

          final subscribeBtn = find.byKey(const Key('banner_subscribe_button'));
          expect(subscribeBtn, findsOneWidget);

          await tester.ensureVisible(subscribeBtn);
          await tester.pumpAndSettle();
          await tester.tap(subscribeBtn);
          await tester.pumpAndSettle();

          expect(find.byType(SubscriptionScreen), findsOneWidget);
        },
      );

      testWidgets('tapping settings icon in AppBar opens SettingsScreen', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        final settingsBtn = find.byKey(const Key('home_settings_button'));
        expect(settingsBtn, findsOneWidget);

        await tester.tap(settingsBtn);
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

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

          final startBtn = find.byKey(const Key('start_overlay_button'));
          await tester.ensureVisible(startBtn);
          await tester.pumpAndSettle();
          await tester.tap(startBtn);
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
          final startBtn = find.byKey(const Key('start_overlay_button'));
          await tester.ensureVisible(startBtn);
          await tester.pumpAndSettle();
          await tester.tap(startBtn);
          await tester.pumpAndSettle();
          expect(find.text('Status: Aktif'), findsOneWidget);

          // 2. Deactivate
          final stopBtn = find.byKey(const Key('stop_overlay_button'));
          await tester.ensureVisible(stopBtn);
          await tester.pumpAndSettle();
          await tester.tap(stopBtn);
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

      testWidgets(
        'shows AppUpdateDialog when new update is available on home load',
        (WidgetTester tester) async {
          const updateInfo = AppUpdateInfo(
            type: AppUpdateType.optional,
            currentVersionCode: 1,
            currentVersionName: '1.0.0',
            latestVersionCode: 2,
            latestVersionName: '1.1.0',
            minVersionCode: 1,
            downloadUrl: 'https://drive.google.com/apk-v2',
            releaseNotes: 'Fitur baru!',
          );

          await tester.pumpWidget(
            createWidgetUnderTest(updateInfo: updateInfo),
          );
          await tester.pumpAndSettle();

          expect(find.text('Pembaruan Aplikasi Tersedia'), findsOneWidget);
          expect(find.text('Fitur baru!'), findsOneWidget);
        },
      );
    },
  );
}
