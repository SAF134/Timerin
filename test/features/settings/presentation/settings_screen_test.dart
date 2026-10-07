import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/settings/presentation/settings_screen.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUserRepository extends Mock implements UserRepository {}

class MockOverlayPermissionService extends Mock
    implements OverlayPermissionService {}

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

class MockAppUpdateService extends Mock implements AppUpdateService {}

class FakeAccessNotifier extends AccessNotifier {
  FakeAccessNotifier(this._initialState);

  final AccessState _initialState;

  @override
  AccessState build() => _initialState;
}

void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockUserRepository mockUserRepo;
  late MockOverlayPermissionService mockPermissionService;
  late MockUrlLauncherService mockLauncherService;
  late MockAppUpdateService mockUpdateService;

  final testDate = DateTime(2026, 11, 20, 15, 30);
  final testUserModel = UserModel(
    uid: 'user_settings_123',
    email: 'settings_user@example.com',
    displayName: 'Raka Gamer',
    subscriptionEndsAt: testDate,
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockUserRepo = MockUserRepository();
    mockPermissionService = MockOverlayPermissionService();
    mockLauncherService = MockUrlLauncherService();
    mockUpdateService = MockAppUpdateService();

    when(() => mockUser.uid).thenReturn('user_settings_123');
    when(() => mockUser.email).thenReturn('settings_user@example.com');
    when(() => mockUser.displayName).thenReturn('Raka Gamer');
    when(() => mockAuthService.currentUser).thenReturn(mockUser);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
    when(
      () => mockPermissionService.isOverlayPermissionGranted(),
    ).thenAnswer((_) async => true);
    when(
      () => mockPermissionService.requestOverlayPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => mockUserRepo.requestAccountDeletion(any()),
    ).thenAnswer((_) async {});
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
      status: AccessStatus.berlangganan,
      remainingAccess: Duration(days: 20),
    ),
    UserModel? userModel,
  }) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        overlayPermissionServiceProvider.overrideWithValue(
          mockPermissionService,
        ),
        urlLauncherServiceProvider.overrideWithValue(mockLauncherService),
        appUpdateServiceProvider.overrideWithValue(mockUpdateService),
        currentUserModelProvider.overrideWith(
          (ref) => Stream.value(userModel ?? testUserModel),
        ),
        accessStateProvider.overrideWith(() => FakeAccessNotifier(accessState)),
      ],
      child: MaterialApp(theme: AppTheme.theme, home: const SettingsScreen()),
    );
  }

  group('SettingsScreen Tests (SCR-006, FR-017)', () {
    testWidgets('renders account details, subscription status, and version', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Raka Gamer'), findsOneWidget);
      expect(find.text('settings_user@example.com'), findsOneWidget);
      expect(find.text('user_settings_123'), findsOneWidget);
      expect(find.text('Berlangganan Aktif'), findsOneWidget);
      expect(find.text('sisa 20 hari'), findsOneWidget);
      expect(find.text('20/11/2026, 15:30'), findsOneWidget);
      expect(find.text(SettingsScreen.appVersion), findsOneWidget);
    });

    testWidgets(
      'tapping Kelola / Perpanjang Langganan opens SubscriptionScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final subBtn = find.byKey(const Key('settings_subscription_button'));
        await tester.ensureVisible(subBtn);
        await tester.pumpAndSettle();
        await tester.tap(subBtn);
        await tester.pumpAndSettle();

        expect(find.byType(SubscriptionScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Buka Setelan Izin Sistem calls requestOverlayPermission',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Belum Diizinkan'), findsOneWidget);

        final permBtn = find.byKey(
          const Key('open_permission_settings_button'),
        );
        await tester.ensureVisible(permBtn);
        await tester.pumpAndSettle();
        await tester.tap(permBtn);
        await tester.pumpAndSettle();

        verify(
          () => mockPermissionService.requestOverlayPermission(),
        ).called(1);
      },
    );

    testWidgets('expanding battery optimization tile shows brand tips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('battery_optimization_tile'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        find.text('Xiaomi / Redmi / POCO (MIUI / HyperOS)'),
        findsOneWidget,
      );
      expect(find.text('Samsung (One UI)'), findsOneWidget);
      expect(find.text('Oppo / Realme (ColorOS / Realme UI)'), findsOneWidget);
      expect(find.text('Vivo / iQOO (Funtouch OS)'), findsOneWidget);
    });

    testWidgets(
      'tapping Kebijakan Privasi opens dialog and Buka di Browser calls launchExternalUrl',
      (WidgetTester tester) async {
        when(
          () => mockLauncherService.launchExternalUrl(any()),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final privacyTile = find.byKey(const Key('privacy_policy_tile'));
        await tester.ensureVisible(privacyTile);
        await tester.pumpAndSettle();
        await tester.tap(privacyTile);
        await tester.pumpAndSettle();

        expect(find.text('Kebijakan Privasi Timerin'), findsOneWidget);

        await tester.tap(find.text('Buka di Browser'));
        await tester.pumpAndSettle();

        verify(
          () => mockLauncherService.launchExternalUrl(
            SettingsScreen.privacyPolicyUrl,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping Keluar shows dialog, confirming signs out to LoginScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final logoutBtn = find.byKey(const Key('settings_logout_button'));
        await tester.ensureVisible(logoutBtn);
        await tester.pumpAndSettle();
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();

        expect(find.text('Konfirmasi Keluar'), findsOneWidget);

        await tester.tap(find.byKey(const Key('confirm_sign_out_button')));
        await tester.pumpAndSettle();

        verify(() => mockAuthService.signOut()).called(1);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Minta Hapus Akun shows dialog, confirming requests deletion',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final deleteBtn = find.byKey(
          const Key('settings_delete_account_button'),
        );
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Minta Hapus Akun'),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('confirm_delete_account_button')),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockUserRepo.requestAccountDeletion('user_settings_123'),
        ).called(1);
        expect(
          find.text('Permintaan hapus akun telah dikirimkan ke pengembang.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Periksa Pembaruan shows snackbar when app is up to date',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final checkUpdateTile = find.byKey(const Key('check_update_tile'));
        await tester.ensureVisible(checkUpdateTile);
        await tester.pumpAndSettle();
        await tester.tap(checkUpdateTile);
        await tester.pumpAndSettle();

        expect(
          find.text('Aplikasi sudah dalam versi terbaru (v1.0.0).'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Periksa Pembaruan opens AppUpdateDialog when new version is available',
      (WidgetTester tester) async {
        when(() => mockUpdateService.checkUpdate()).thenAnswer(
          (_) async => const AppUpdateInfo(
            type: AppUpdateType.optional,
            currentVersionCode: 1,
            currentVersionName: '1.0.0',
            latestVersionCode: 2,
            latestVersionName: '1.1.0',
            minVersionCode: 1,
            downloadUrl: 'https://drive.google.com/apk-v2',
            releaseNotes: 'Fitur baru!',
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final checkUpdateTile = find.byKey(const Key('check_update_tile'));
        await tester.ensureVisible(checkUpdateTile);
        await tester.pumpAndSettle();
        await tester.tap(checkUpdateTile);
        await tester.pumpAndSettle();

        expect(find.text('Pembaruan Aplikasi Tersedia'), findsOneWidget);
        expect(find.text('Fitur baru!'), findsOneWidget);
      },
    );
  });
}
