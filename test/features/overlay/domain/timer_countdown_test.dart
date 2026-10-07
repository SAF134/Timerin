import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/features/overlay/domain/timer_countdown.dart';

class FakeMonotonicStopwatch implements MonotonicStopwatch {
  int _elapsedMs = 0;
  bool _running = false;

  void advance(int milliseconds) {
    if (_running) {
      _elapsedMs += milliseconds;
    }
  }

  @override
  int get elapsedMilliseconds => _elapsedMs;

  @override
  bool get isRunning => _running;

  @override
  void reset() {
    _elapsedMs = 0;
  }

  @override
  void start() {
    _running = true;
  }

  @override
  void stop() {
    _running = false;
  }
}

class FakeTimer implements Timer {
  FakeTimer(this.callback);

  final void Function(Timer) callback;
  bool _isActive = true;
  int _tickCount = 0;

  void triggerTick() {
    if (_isActive) {
      _tickCount++;
      callback(this);
    }
  }

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tickCount;
}

void main() {
  group('TimerCountdown Domain Tests (T-005 / FR-010, NFR-001)', () {
    late FakeMonotonicStopwatch fakeStopwatch;
    FakeTimer? activeTimer;

    TimerCountdown createTestCountdown({
      Duration duration = const Duration(seconds: 30),
      int warningThreshold = 5,
    }) {
      fakeStopwatch = FakeMonotonicStopwatch();
      return TimerCountdown(
        duration: duration,
        warningThresholdSeconds: warningThreshold,
        stopwatchFactory: () => fakeStopwatch,
        timerFactory: (interval, callback) {
          final timer = FakeTimer(callback);
          activeTimer = timer;
          return timer;
        },
      );
    }

    test('initial state is idle with full duration and 1.0 progress', () {
      final countdown = createTestCountdown(
        duration: const Duration(seconds: 30),
      );

      expect(countdown.status, TimerCountdownStatus.idle);
      expect(countdown.isIdle, isTrue);
      expect(countdown.isRunning, isFalse);
      expect(countdown.isFinished, isFalse);
      expect(countdown.remainingSeconds, 30);
      expect(countdown.totalSeconds, 30);
      expect(countdown.progress, 1.0);
      expect(countdown.formatTime(), '30');
      expect(countdown.formatTime(showMinutesSeconds: true), '00:30');

      countdown.dispose();
    });

    test(
      'startOrRestart transitions to running and starts monotonic ticker',
      () {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 30),
        );

        bool notified = false;
        countdown.addListener(() => notified = true);

        countdown.startOrRestart();

        expect(countdown.status, TimerCountdownStatus.running);
        expect(countdown.isRunning, isTrue);
        expect(fakeStopwatch.isRunning, isTrue);
        expect(activeTimer, isNotNull);
        expect(notified, isTrue);

        countdown.dispose();
      },
    );

    test(
      'countdown transitions from running -> warning -> finished monotonically',
      () {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 10),
          warningThreshold: 3,
        );

        countdown.startOrRestart();
        expect(countdown.status, TimerCountdownStatus.running);
        expect(countdown.remainingSeconds, 10);

        // Advance by 6 seconds -> 4 seconds remaining (> 3 threshold)
        fakeStopwatch.advance(6000);
        activeTimer?.triggerTick();
        expect(countdown.status, TimerCountdownStatus.running);
        expect(countdown.remainingSeconds, 4);

        // Advance by 1 second -> 3 seconds remaining (<= 3 threshold -> warning)
        fakeStopwatch.advance(1000);
        activeTimer?.triggerTick();
        expect(countdown.status, TimerCountdownStatus.warning);
        expect(countdown.remainingSeconds, 3);

        // Advance by 2.5 seconds -> 0.5s remaining (ceil = 1s, warning)
        fakeStopwatch.advance(2500);
        activeTimer?.triggerTick();
        expect(countdown.status, TimerCountdownStatus.warning);
        expect(countdown.remainingSeconds, 1);

        // Advance by 500ms -> 10s total elapsed -> finished
        fakeStopwatch.advance(500);
        activeTimer?.triggerTick();
        expect(countdown.status, TimerCountdownStatus.finished);
        expect(countdown.isFinished, isTrue);
        expect(countdown.remainingSeconds, 0);
        expect(countdown.progress, 0.0);
        expect(countdown.formatTime(), '0');

        // Tapping when finished restarts to running from full duration
        countdown.startOrRestart();
        expect(countdown.status, TimerCountdownStatus.running);
        expect(countdown.remainingSeconds, 10);
        expect(countdown.progress, 1.0);

        countdown.dispose();
      },
    );

    test('startOrRestart while running restarts countdown from beginning', () {
      final countdown = createTestCountdown(
        duration: const Duration(seconds: 20),
      );

      countdown.startOrRestart();
      fakeStopwatch.advance(15000);
      activeTimer?.triggerTick();
      expect(countdown.remainingSeconds, 5);

      // Tap again while running
      countdown.startOrRestart();
      expect(countdown.status, TimerCountdownStatus.running);
      expect(countdown.remainingSeconds, 20);
      expect(fakeStopwatch.elapsedMilliseconds, 0);

      countdown.dispose();
    });

    test('reset stops stopwatch and restores idle status', () {
      final countdown = createTestCountdown(
        duration: const Duration(seconds: 30),
      );

      countdown.startOrRestart();
      fakeStopwatch.advance(10000);
      activeTimer?.triggerTick();
      expect(countdown.status, TimerCountdownStatus.running);

      countdown.reset();
      expect(countdown.status, TimerCountdownStatus.idle);
      expect(countdown.remainingSeconds, 30);
      expect(countdown.isIdle, isTrue);
      expect(fakeStopwatch.isRunning, isFalse);

      countdown.dispose();
    });

    test('formatTime correctly formats mm:ss for durations > 60s', () {
      final countdown = createTestCountdown(
        duration: const Duration(seconds: 125),
      );

      expect(countdown.formatTime(), '125');
      expect(countdown.formatTime(showMinutesSeconds: true), '02:05');

      countdown.dispose();
    });
  });
}
