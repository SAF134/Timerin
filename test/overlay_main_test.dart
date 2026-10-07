import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/features/overlay/presentation/overlay_container.dart';
import 'package:timerin/features/overlay/presentation/overlay_timer_bubble.dart';
import 'package:timerin/overlay_main.dart';

void main() {
  group('OverlayApp Entry Point Tests (T-005, T-007 / SCR-007, FR-010)', () {
    testWidgets(
      'renders OverlayApp with transparent Scaffold and OverlayContainer',
      (tester) async {
        await tester.pumpWidget(const OverlayApp());

        expect(find.byType(OverlayApp), findsOneWidget);
        expect(find.byType(OverlayContainer), findsOneWidget);
        expect(find.byType(OverlayTimerBubble), findsWidgets);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.transparent);
      },
    );
  });
}
