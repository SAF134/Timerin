import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/main.dart';

void main() {
  testWidgets(
    'TimerinApp renders successfully with empty placeholder scaffold',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: TimerinApp()));

      expect(find.byType(Scaffold), findsOneWidget);
    },
  );
}
