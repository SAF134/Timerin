import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/services/access_cache.dart';
import 'package:timerin/features/subscription/services/access_service.dart';
import 'package:timerin/features/subscription/services/monotonic_clock.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockOverlayServiceController extends Mock
    implements OverlayServiceController {}

class FakeMonotonicClock implements MonotonicClock {
  int _elapsed = 0;

  void advance(int milliseconds) {
    _elapsed += milliseconds;
  }

  @override
  int get elapsedMilliseconds => _elapsed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserRepository mockUserRepo;
  late MockOverlayServiceController mockOverlayController;
  late SharedPreferences prefs;
  late AccessCache cache;
  late FakeMonotonicClock fakeClock;
  late AccessService accessService;

  const testUid = 'user_123';
  const bootSession = 'session_test_abc';

  setUp(() async {
    mockUserRepo = MockUserRepository();
    mockOverlayController = MockOverlayServiceController();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    cache = AccessCache(prefs: prefs);
    fakeClock = FakeMonotonicClock();

    accessService = AccessService(
      userRepository: mockUserRepo,
      overlayController: mockOverlayController,
      cache: cache,
      monotonicClock: fakeClock,
      bootSessionId: bootSession,
    );

    when(() => mockOverlayController.stopOverlay()).thenAnswer((_) async {});
  });

  group('AccessService Logic & Evaluation Tests (T-009 / PRD §3, TECH §5)', () {
    test(
      'evaluateAccess returns status baru when trial not started & not subscribed',
      () {
        final now = DateTime(2026, 10, 7, 12, 0);
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          createdAt: now,
        );

        final result = AccessService.evaluateAccess(
          user: user,
          serverTime: now,
        );

        expect(result.status, AccessStatus.baru);
        expect(result.remainingAccess, Duration.zero);
        expect(result.canActivateOverlay, isFalse);
      },
    );

    test(
      'evaluateAccess returns status trial when within 24 hours of trialStartedAt',
      () {
        final serverTime = DateTime(2026, 10, 7, 18, 0);
        final trialStart = DateTime(2026, 10, 7, 12, 0); // 6 hours ago
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: trialStart,
        );

        final result = AccessService.evaluateAccess(
          user: user,
          serverTime: serverTime,
        );

        expect(result.status, AccessStatus.trial);
        expect(result.remainingAccess, const Duration(hours: 18));
        expect(result.canActivateOverlay, isTrue);
      },
    );

    test(
      'evaluateAccess returns status habis when trial started > 24 hours ago',
      () {
        final serverTime = DateTime(2026, 10, 8, 13, 0);
        final trialStart = DateTime(2026, 10, 7, 12, 0); // 25 hours ago
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: trialStart,
        );

        final result = AccessService.evaluateAccess(
          user: user,
          serverTime: serverTime,
        );

        expect(result.status, AccessStatus.habis);
        expect(result.remainingAccess, Duration.zero);
        expect(result.canActivateOverlay, isFalse);
      },
    );

    test('evaluateAccess prioritizes active subscription over trial', () {
      final serverTime = DateTime(2026, 10, 7, 12, 0);
      final subEnd = DateTime(2026, 10, 17, 12, 0); // 10 days in future
      final user = UserModel(
        uid: testUid,
        email: 'pemain@example.com',
        displayName: 'Pemain',
        trialStartedAt: serverTime, // trial also active
        subscriptionEndsAt: subEnd,
      );

      final result = AccessService.evaluateAccess(
        user: user,
        serverTime: serverTime,
      );

      expect(result.status, AccessStatus.berlangganan);
      expect(result.remainingAccess, const Duration(days: 10));
      expect(result.canActivateOverlay, isTrue);
    });

    test(
      'evaluateAccess returns status habis when subscription has expired and trial is null',
      () {
        final serverTime = DateTime(2026, 10, 8, 12, 0);
        final subEnd = DateTime(2026, 10, 7, 12, 0); // expired yesterday
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          subscriptionEndsAt: subEnd,
        );

        final result = AccessService.evaluateAccess(
          user: user,
          serverTime: serverTime,
        );

        expect(result.status, AccessStatus.habis);
        expect(result.remainingAccess, Duration.zero);
        expect(result.canActivateOverlay, isFalse);
      },
    );

    test(
      'evaluateAccess returns status habis when subscription and trial have both expired',
      () {
        final serverTime = DateTime(2026, 10, 8, 12, 0);
        final subEnd = DateTime(2026, 10, 7, 12, 0); // expired yesterday
        final trialStart = DateTime(2026, 9, 1, 12, 0); // long ago
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: trialStart,
          subscriptionEndsAt: subEnd,
        );

        final result = AccessService.evaluateAccess(
          user: user,
          serverTime: serverTime,
        );

        expect(result.status, AccessStatus.habis);
        expect(result.remainingAccess, Duration.zero);
        expect(result.canActivateOverlay, isFalse);
      },
    );

    test(
      'checkAccess syncs server time, saves cache, and evaluates status',
      () async {
        final serverTime = DateTime(2026, 10, 7, 12, 0);
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: serverTime.subtract(const Duration(hours: 4)),
        );

        when(
          () => mockUserRepo.syncServerTime(testUid),
        ).thenAnswer((_) async => serverTime);
        when(() => mockUserRepo.getUser(testUid)).thenAnswer((_) async => user);

        final accessState = await accessService.checkAccess(testUid);

        expect(accessState.status, AccessStatus.trial);
        expect(accessState.remainingAccess, const Duration(hours: 20));

        // Verify cache was saved
        final cached = cache.load();
        expect(cached, isNotNull);
        expect(cached!['status'], AccessStatus.trial);
        expect(cached['remainingMs'], const Duration(hours: 20).inMilliseconds);
      },
    );

    test(
      'checkAccess stops overlay when access status is habis (FR-014)',
      () async {
        final serverTime = DateTime(2026, 10, 8, 15, 0);
        final user = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: DateTime(2026, 10, 7, 12, 0), // expired 27 hrs ago
        );

        when(
          () => mockUserRepo.syncServerTime(testUid),
        ).thenAnswer((_) async => serverTime);
        when(() => mockUserRepo.getUser(testUid)).thenAnswer((_) async => user);

        final accessState = await accessService.checkAccess(testUid);

        expect(accessState.status, AccessStatus.habis);
        verify(() => mockOverlayController.stopOverlay()).called(1);
      },
    );

    test(
      'startTrial atomically writes trialStartedAt and transitions to trial (FR-013)',
      () async {
        final serverTime = DateTime(2026, 10, 7, 12, 0);
        final userWithTrial = UserModel(
          uid: testUid,
          email: 'pemain@example.com',
          displayName: 'Pemain',
          trialStartedAt: serverTime,
        );

        when(
          () => mockUserRepo.startTrial(testUid),
        ).thenAnswer((_) async => userWithTrial);
        when(
          () => mockUserRepo.syncServerTime(testUid),
        ).thenAnswer((_) async => serverTime);
        when(
          () => mockUserRepo.getUser(testUid),
        ).thenAnswer((_) async => userWithTrial);

        final accessState = await accessService.startTrial(testUid);

        verify(() => mockUserRepo.startTrial(testUid)).called(1);
        expect(accessState.status, AccessStatus.trial);
        expect(accessState.remainingAccess, const Duration(hours: 24));
      },
    );

    test(
      'offline fallback uses monotonic clock; immune to system time changes (NFR-001, NFR-004)',
      () async {
        // 1. Seed cache with 10 hours remaining
        await cache.save(
          status: AccessStatus.trial,
          remainingMs: const Duration(hours: 10).inMilliseconds,
          monotonicAnchorMs: 0,
          serverTimeMs: DateTime(2026, 10, 7, 12, 0).millisecondsSinceEpoch,
          bootSessionId: bootSession,
        );

        // Simulate network failure
        when(
          () => mockUserRepo.syncServerTime(testUid),
        ).thenThrow(Exception('Network offline'));

        // Advance monotonic clock by 3 hours
        fakeClock.advance(const Duration(hours: 3).inMilliseconds);

        final offlineState = await accessService.checkAccess(testUid);

        expect(offlineState.status, AccessStatus.trial);
        expect(offlineState.remainingAccess, const Duration(hours: 7));

        // Advance monotonic clock past remaining 7 hours
        fakeClock.advance(const Duration(hours: 8).inMilliseconds);

        final expiredState = await accessService.checkAccess(testUid);

        expect(expiredState.status, AccessStatus.habis);
        expect(expiredState.remainingAccess, Duration.zero);
        verify(() => mockOverlayController.stopOverlay()).called(1);
      },
    );

    test(
      'offline fallback returns habis if boot session changed (TECH §5 item 4)',
      () async {
        // Cache created in previous boot session
        await cache.save(
          status: AccessStatus.trial,
          remainingMs: const Duration(hours: 10).inMilliseconds,
          monotonicAnchorMs: 0,
          serverTimeMs: DateTime(2026, 10, 7, 12, 0).millisecondsSinceEpoch,
          bootSessionId: 'previous_boot_session_xyz',
        );

        // Simulate network failure
        when(
          () => mockUserRepo.syncServerTime(testUid),
        ).thenThrow(Exception('Network offline'));

        final rebootState = await accessService.checkAccess(testUid);

        // Must be locked until verified online
        expect(rebootState.status, AccessStatus.habis);
        expect(rebootState.remainingAccess, Duration.zero);
      },
    );
  });
}
