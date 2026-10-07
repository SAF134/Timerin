import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/features/overlay/presentation/overlay_container.dart';
import 'package:timerin/features/overlay/presentation/overlay_timer_bubble.dart';

void main() {
  group('OverlayContainer Widget Tests (T-007 / FR-005, FR-009, FR-010)', () {
    testWidgets('renders exact number of bubbles specified by timerCount', (
      WidgetTester tester,
    ) async {
      const settings = TimerSettings(
        timerCount: 4,
        orientation: TimerOrientation.vertical,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: OverlayContainer(settings: settings)),
          ),
        ),
      );

      expect(find.byType(OverlayTimerBubble), findsNWidgets(4));
      expect(
        find.byKey(const ValueKey('overlay_timer_bubble_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('overlay_timer_bubble_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('overlay_timer_bubble_2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('overlay_timer_bubble_3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('overlay_timer_bubble_4')),
        findsNothing,
      );
    });

    testWidgets('renders Column when vertical and Row when horizontal', (
      WidgetTester tester,
    ) async {
      // 1. Vertical
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OverlayContainer(
                settings: TimerSettings(
                  timerCount: 3,
                  orientation: TimerOrientation.vertical,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);

      // 2. Horizontal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OverlayContainer(
                settings: TimerSettings(
                  timerCount: 3,
                  orientation: TimerOrientation.horizontal,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets(
      'tapping timer 1 only starts timer 1 without affecting timer 2 (FR-010)',
      (WidgetTester tester) async {
        const settings = TimerSettings(
          timerCount: 2,
          durations: <int>[30, 60, 120, 180, 30],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: OverlayContainer(settings: settings)),
            ),
          ),
        );

        // Initial state: Timer 1 shows 30, Timer 2 shows 60
        expect(find.text('30'), findsOneWidget);
        expect(find.text('60'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Tap Timer 1 only
        await tester.tap(find.byKey(const ValueKey('overlay_timer_bubble_0')));
        await tester.pump();

        // Timer 1 now has active circular progress indicator (running)
        // Timer 2 has no progress indicator (still idle)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('60'), findsOneWidget);
      },
    );
  });
}
