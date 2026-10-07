import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/onboarding_repository.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/home/presentation/widgets/timer_settings_card.dart';

void main() {
  group('TimerSettingsCard Widget Tests (T-007 / FR-005..FR-009, SCR-004)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(
            body: SingleChildScrollView(child: TimerSettingsCard()),
          ),
        ),
      );
    }

    testWidgets('renders all settings sections and live preview', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan Overlay'), findsOneWidget);
      expect(find.text('Jumlah Timer'), findsOneWidget);
      expect(find.text('Format Waktu'), findsOneWidget);
      expect(find.text('Susunan Timer'), findsOneWidget);
      expect(find.text('Ukuran Overlay'), findsOneWidget);
      expect(find.text('Durasi Tiap Timer'), findsOneWidget);
      expect(find.text('Pratinjau Overlay'), findsOneWidget);

      // Default count is 3
      expect(find.text('Timer 1'), findsOneWidget);
      expect(find.text('Timer 2'), findsOneWidget);
      expect(find.text('Timer 3'), findsOneWidget);
      expect(find.text('Timer 4'), findsNothing);
    });

    testWidgets('tapping timer count chip 4 updates count to 4 timers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_count_chip_4')));
      await tester.pumpAndSettle();

      expect(find.text('Timer 1'), findsOneWidget);
      expect(find.text('Timer 2'), findsOneWidget);
      expect(find.text('Timer 3'), findsOneWidget);
      expect(find.text('Timer 4'), findsOneWidget);
      expect(find.text('Timer 5'), findsNothing);
    });

    testWidgets('toggling time format chip updates format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('format_mm_ss_chip')));
      await tester.pumpAndSettle();

      final repo = TimerSettingsRepository(prefs: prefs);
      expect(repo.getSettings().timeFormat, TimeDisplayFormat.minutesSeconds);
    });

    testWidgets('toggling orientation chip updates orientation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('orientation_horizontal_chip')));
      await tester.pumpAndSettle();

      final repo = TimerSettingsRepository(prefs: prefs);
      expect(repo.getSettings().orientation, TimerOrientation.horizontal);
    });

    testWidgets('moving scale slider updates scale percentage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final sliderFinder = find.byKey(const Key('scale_slider'));
      expect(sliderFinder, findsOneWidget);

      // Slide towards right
      await tester.drag(sliderFinder, const Offset(50.0, 0.0));
      await tester.pumpAndSettle();

      final repo = TimerSettingsRepository(prefs: prefs);
      expect(repo.getSettings().scale, isNot(1.0));
    });

    testWidgets('custom duration dialog allows updating duration to 5..600s', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap duration dropdown for Timer 1
      await tester.tap(find.byKey(const Key('timer_duration_dropdown_0')));
      await tester.pumpAndSettle();

      // Tap custom option
      await tester.tap(find.text('Kustom (5–600 dtk)...'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Durasi Timer 1'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets);

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Durasi Timer 1'), findsNothing);
    });
  });
}
