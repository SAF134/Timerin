import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/crashlytics_service.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
  });

  group('CrashlyticsService Tests (T-002 / NFR-009)', () {
    test('initialize sets up crashlytics collection without error', () async {
      when(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(any<bool>()),
      ).thenAnswer((_) async {});

      await CrashlyticsService.initialize(instance: mockCrashlytics);

      verify(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(any<bool>()),
      ).called(1);
    });

    test(
      'recordNonFatal passes exception and stack trace without PII',
      () async {
        when(
          () => mockCrashlytics.recordError(
            any<Object>(),
            any<StackTrace?>(),
            reason: any<Object?>(named: 'reason'),
            fatal: any<bool>(named: 'fatal'),
          ),
        ).thenAnswer((_) async {});

        final exception = Exception('Non-fatal test error');
        final stack = StackTrace.current;

        await CrashlyticsService.recordNonFatal(
          exception,
          stack,
          reason: 'test reason',
          instance: mockCrashlytics,
        );

        verify(
          () => mockCrashlytics.recordError(
            exception,
            stack,
            reason: 'test reason',
            fatal: false,
          ),
        ).called(1);
      },
    );
  });
}
