import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerSettingsRepository & Notifier Tests (T-007 / FR-018)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('getSettings returns default when SharedPreferences is empty', () {
      final repo = TimerSettingsRepository(prefs: prefs);
      final settings = repo.getSettings();

      expect(settings, equals(const TimerSettings()));
      expect(settings.timerCount, 3);
    });

    test(
      'saveSettings persists and getSettings recovers configuration',
      () async {
        final repo = TimerSettingsRepository(prefs: prefs);
        const custom = TimerSettings(
          timerCount: 5,
          timeFormat: TimeDisplayFormat.minutesSeconds,
          orientation: TimerOrientation.horizontal,
          scale: 1.2,
          durations: <int>[30, 45, 60, 90, 120],
        );

        final saved = await repo.saveSettings(custom);
        expect(saved, isTrue);

        final reloaded = repo.getSettings();
        expect(reloaded, equals(custom));
      },
    );

    test(
      'TimerSettingsNotifier updates and saves across state mutations',
      () async {
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );

        final notifier = container.read(timerSettingsProvider.notifier);

        expect(container.read(timerSettingsProvider).timerCount, 3);

        // 1. setTimerCount
        await notifier.setTimerCount(5);
        expect(container.read(timerSettingsProvider).timerCount, 5);

        // 2. setTimeFormat
        await notifier.setTimeFormat(TimeDisplayFormat.minutesSeconds);
        expect(
          container.read(timerSettingsProvider).timeFormat,
          TimeDisplayFormat.minutesSeconds,
        );

        // 3. setOrientation
        await notifier.setOrientation(TimerOrientation.horizontal);
        expect(
          container.read(timerSettingsProvider).orientation,
          TimerOrientation.horizontal,
        );

        // 4. setScale
        await notifier.setScale(1.4);
        expect(container.read(timerSettingsProvider).scale, 1.4);

        // 5. setTimerDuration
        await notifier.setTimerDuration(2, 75);
        expect(container.read(timerSettingsProvider).getDurationFor(2), 75);

        // Verify repo persisted all changes
        final repo = container.read(timerSettingsRepositoryProvider);
        final persisted = repo.getSettings();
        expect(persisted.timerCount, 5);
        expect(persisted.timeFormat, TimeDisplayFormat.minutesSeconds);
        expect(persisted.orientation, TimerOrientation.horizontal);
        expect(persisted.scale, 1.4);
        expect(persisted.getDurationFor(2), 75);

        container.dispose();
      },
    );
  });
}
