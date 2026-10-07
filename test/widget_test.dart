import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/main.dart';

void main() {
  testWidgets('TimerinApp renders successfully with initial SplashScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TimerinApp(),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Timerin'), findsOneWidget);
  });
}
