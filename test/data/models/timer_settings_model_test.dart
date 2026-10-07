import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/data/models/timer_settings_model.dart';

void main() {
  group('TimerSettings Model Tests (T-007 / FR-005..FR-009, FR-018)', () {
    test('default constructor initializes with valid defaults', () {
      const settings = TimerSettings();

      expect(settings.timerCount, 3);
      expect(settings.timeFormat, TimeDisplayFormat.seconds);
      expect(settings.orientation, TimerOrientation.vertical);
      expect(settings.scale, 1.0);
      expect(settings.durations, <int>[30, 60, 120, 180, 30]);
    });

    test('getDurationFor returns clamped duration within 5..600s range', () {
      const settings = TimerSettings(durations: <int>[30, 60, 120, 180, 30]);

      expect(settings.getDurationFor(0), 30);
      expect(settings.getDurationFor(1), 60);
      expect(settings.getDurationFor(2), 120);
      expect(settings.getDurationFor(3), 180);
      expect(settings.getDurationFor(4), 30);
      expect(settings.getDurationFor(99), 30); // out of bounds fallback
    });

    test('copyWith clamps timerCount (1..5) and scale (0.5..1.5)', () {
      const settings = TimerSettings();

      final highCount = settings.copyWith(timerCount: 10);
      expect(highCount.timerCount, 5);

      final lowCount = settings.copyWith(timerCount: 0);
      expect(lowCount.timerCount, 1);

      final highScale = settings.copyWith(scale: 2.5);
      expect(highScale.scale, 1.5);

      final lowScale = settings.copyWith(scale: 0.1);
      expect(lowScale.scale, 0.5);
    });

    test('copyWithDuration updates duration for specific timer index', () {
      const settings = TimerSettings();

      final updated = settings.copyWithDuration(1, 90);
      expect(updated.getDurationFor(1), 90);
      expect(updated.getDurationFor(0), 30); // untouched

      // Clamps custom duration to 5..600
      final clampedLow = settings.copyWithDuration(0, 1);
      expect(clampedLow.getDurationFor(0), 5);

      final clampedHigh = settings.copyWithDuration(0, 9999);
      expect(clampedHigh.getDurationFor(0), 600);
    });

    test(
      'serialization toMap / toJson and fromMap / fromJson roundtrips accurately',
      () {
        const original = TimerSettings(
          timerCount: 4,
          timeFormat: TimeDisplayFormat.minutesSeconds,
          orientation: TimerOrientation.horizontal,
          scale: 1.25,
          durations: <int>[60, 120, 180, 240, 30],
        );

        final jsonString = original.toJson();
        final restored = TimerSettings.fromJson(jsonString);

        expect(restored, equals(original));
        expect(restored.timerCount, 4);
        expect(restored.timeFormat, TimeDisplayFormat.minutesSeconds);
        expect(restored.orientation, TimerOrientation.horizontal);
        expect(restored.scale, 1.25);
        expect(restored.durations, <int>[60, 120, 180, 240, 30]);
      },
    );

    test('fromJson falls back gracefully on corrupted json string', () {
      final fallback = TimerSettings.fromJson('not valid json {');
      expect(fallback, equals(const TimerSettings()));
    });

    test('TimerDurationPresets helper formats labels cleanly', () {
      expect(TimerDurationPresets.formatDurationLabel(30), '30 dtk');
      expect(TimerDurationPresets.formatDurationLabel(60), '1 mnt');
      expect(TimerDurationPresets.formatDurationLabel(120), '2 mnt');
      expect(TimerDurationPresets.formatDurationLabel(180), '3 mnt');
      expect(TimerDurationPresets.formatDurationLabel(240), '4 mnt');
      expect(TimerDurationPresets.formatDurationLabel(45), '45 dtk');
    });
  });
}
