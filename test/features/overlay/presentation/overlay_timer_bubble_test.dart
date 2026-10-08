import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/features/overlay/domain/timer_countdown.dart';
import 'package:timerin/features/overlay/presentation/overlay_timer_bubble.dart';

import '../domain/timer_countdown_test.dart';

void main() {
  group('OverlayTimerBubble Widget Tests (T-005 / FR-010, SCR-007)', () {
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

    testWidgets('renders idle state with initial duration text and 56dp size', (
      tester,
    ) async {
      final countdown = createTestCountdown(
        duration: const Duration(seconds: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: OverlayTimerBubble(countdown: countdown)),
          ),
        ),
      );

      expect(find.text('30'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify bubble container size (56 dp)
      final sizeFinder = find.byType(SizedBox).first;
      final size = tester.getSize(sizeFinder);
      expect(size.width, 56.0);
      expect(size.height, 56.0);

      countdown.dispose();
    });

    testWidgets(
      'tapping bubble starts countdown and changes to running color',
      (tester) async {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 30),
        );
        bool tapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OverlayTimerBubble(
                  countdown: countdown,
                  onTap: () => tapCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OverlayTimerBubble));
        // Tunggu debounce double tap recognizer (300ms)
        await tester.pump(const Duration(milliseconds: 300));

        expect(tapCalled, isTrue);
        expect(countdown.isRunning, isTrue);
        expect(find.text('30'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        countdown.dispose();
      },
    );

    testWidgets(
      'double tapping bubble resets countdown to beginning without running',
      (tester) async {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: OverlayTimerBubble(countdown: countdown)),
            ),
          ),
        );

        // 1. Single tap untuk memulai
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));
        expect(countdown.isRunning, isTrue);

        // 2. Berjalan selama 10 detik
        fakeStopwatch.advance(10000);
        activeTimer?.triggerTick();
        await tester.pump();
        expect(find.text('20'), findsOneWidget);

        // 3. Double tap untuk reset
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));

        // Timer kembali ke awal (30) dan tidak berjalan (idle)
        expect(countdown.status, TimerCountdownStatus.idle);
        expect(countdown.isRunning, isFalse);
        expect(find.text('30'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        countdown.dispose();
      },
    );

    testWidgets(
      'ticking countdown updates remaining seconds and transitions to warning and finished',
      (tester) async {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 10),
          warningThreshold: 3,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: OverlayTimerBubble(countdown: countdown)),
            ),
          ),
        );

        // 1. Start countdown
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('10'), findsOneWidget);

        // 2. Advance time to 4s remaining (running)
        fakeStopwatch.advance(6000);
        activeTimer?.triggerTick();
        await tester.pump();
        expect(find.text('4'), findsOneWidget);

        // 3. Advance time to 3s remaining (warning <= 3s)
        fakeStopwatch.advance(1000);
        activeTimer?.triggerTick();
        await tester.pump();
        expect(find.text('3'), findsOneWidget);
        expect(countdown.status, TimerCountdownStatus.warning);

        // 4. Advance time to finish
        fakeStopwatch.advance(3000);
        activeTimer?.triggerTick();
        await tester.pump();
        expect(countdown.isFinished, isTrue);

        // Indikator visual selesai: angka 0 berwarna hijau accent
        expect(find.text('0'), findsOneWidget);

        // 5. Tap again while finished -> restarts to full duration (10s)
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));
        expect(countdown.status, TimerCountdownStatus.running);
        expect(find.text('10'), findsOneWidget);

        countdown.dispose();
      },
    );

    testWidgets(
      'single tapping while running is ignored, double tapping resets to idle',
      (tester) async {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 20),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: OverlayTimerBubble(countdown: countdown)),
            ),
          ),
        );

        // Start
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));

        fakeStopwatch.advance(15000);
        activeTimer?.triggerTick();
        await tester.pump();
        expect(find.text('5'), findsOneWidget);

        // Single tap while running -> IGNORED (remains 5 and running)
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('5'), findsOneWidget);
        expect(countdown.isRunning, isTrue);

        // Double tap while running -> RESETS to initial duration (20) and stops (idle)
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('20'), findsOneWidget);
        expect(countdown.status, TimerCountdownStatus.idle);
        expect(countdown.isRunning, isFalse);

        countdown.dispose();
      },
    );

    testWidgets('self-contained bubble without external countdown works', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OverlayTimerBubble(initialDuration: Duration(seconds: 15)),
            ),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
      await tester.tap(find.byType(OverlayTimerBubble));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'when isInteractive is false, taps and double taps are ignored',
      (tester) async {
        final countdown = createTestCountdown(
          duration: const Duration(seconds: 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OverlayTimerBubble(
                  countdown: countdown,
                  isInteractive: false,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OverlayTimerBubble));
        await tester.pump(const Duration(milliseconds: 300));

        expect(countdown.isRunning, isFalse);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        countdown.dispose();
      },
    );

    testWidgets(
      'updating initialDuration rebuilds internal countdown duration',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: OverlayTimerBubble(
                  initialDuration: Duration(seconds: 30),
                ),
              ),
            ),
          ),
        );

        expect(find.text('30'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: OverlayTimerBubble(
                  initialDuration: Duration(seconds: 60),
                ),
              ),
            ),
          ),
        );

        expect(find.text('60'), findsOneWidget);
      },
    );
  });
}
