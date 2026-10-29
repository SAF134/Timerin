import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(find.text('Transparansi Overlay'), findsOneWidget);
      expect(find.text('Durasi Tiap Timer'), findsOneWidget);
      expect(find.text('Pratinjau Overlay'), findsOneWidget);

      // Default count is 3
      expect(find.text('Timer 1'), findsOneWidget);
      expect(find.text('Timer 2'), findsOneWidget);
      expect(find.text('Timer 3'), findsOneWidget);
      expect(find.text('Timer 4'), findsNothing);

      expect(find.text('Posisi Overlay'), findsNothing);
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

      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();

      // Slide towards left (since default is 100% / 1.0)
      await tester.drag(sliderFinder, const Offset(-100.0, 0.0));
      await tester.pumpAndSettle();

      final repo = TimerSettingsRepository(prefs: prefs);
      expect(repo.getSettings().scale, lessThan(1.0));
    });

    testWidgets('moving transparency slider updates background opacity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final sliderFinder = find.byKey(const Key('transparency_slider'));
      expect(sliderFinder, findsOneWidget);

      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();

      // Drag slider
      await tester.drag(sliderFinder, const Offset(-80.0, 0.0));
      await tester.pumpAndSettle();

      final repo = TimerSettingsRepository(prefs: prefs);
      expect(repo.getSettings().backgroundOpacity, lessThan(0.85));
    });

    testWidgets('custom duration dialog allows updating duration to 5..600s', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap duration button for Timer 1 (opens custom duration dialog directly)
      await tester.tap(find.byKey(const Key('timer_duration_dropdown_0')));
      await tester.pumpAndSettle();

      // Dialog opens directly
      expect(find.text('Durasi Timer 1'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets);

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Durasi Timer 1'), findsNothing);
    });

    testWidgets(
      'tapping Simpan Pengaturan Overlay saves settings and shows snackbar',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final saveBtn = find.byKey(const Key('save_timer_settings_button'));
        expect(saveBtn, findsOneWidget);

        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Pengaturan overlay berhasil disimpan.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Posisi Overlay section is not rendered on UI (Item 11)', (
      WidgetTester tester,
    ) async {
      final repo = TimerSettingsRepository(prefs: prefs);
      await repo.savePosition(150.0, 300.0);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Posisi Overlay'), findsNothing);
      expect(
        find.byKey(const Key('reset_overlay_position_button')),
        findsNothing,
      );
    });

    testWidgets(
      'when isLocked is true, shows lock banner and ignores interaction',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: TimerSettingsCard(isLocked: true),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('overlay_settings_locked_banner')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Pengaturan dikunci saat overlay aktif. Matikan overlay untuk mengubah pengaturan.',
          ),
          findsOneWidget,
        );

        // Attempt to tap chip 5 - should be ignored
        await tester.tap(find.byKey(const Key('timer_count_chip_5')));
        await tester.pumpAndSettle();

        final repo = TimerSettingsRepository(prefs: prefs);
        expect(repo.getSettings().timerCount, 3); // untouched
      },
    );

    testWidgets('renders separated tap guide cards for 1x Mulai and 2x Reset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Ketuk 1x'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('1X'), findsOneWidget);
      expect(find.text('Ketuk 2x'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('2X'), findsOneWidget);
    });

    testWidgets(
      'toggling vibration switch updates isVibrationEnabled in repository when haptic is enabled',
      (WidgetTester tester) async {
        const vibrationChannel = MethodChannel('com.timerin.app/vibration');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(vibrationChannel, (
              MethodCall call,
            ) async {
              return true;
            });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Getar Saat Timer Habis'), findsOneWidget);

        final switchFinder = find.byKey(const Key('vibration_switch'));
        expect(switchFinder, findsOneWidget);

        await tester.ensureVisible(switchFinder);
        await tester.pumpAndSettle();
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        final repo = TimerSettingsRepository(prefs: prefs);
        expect(repo.getSettings().isVibrationEnabled, isFalse);

        // Toggle back on
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
        expect(repo.getSettings().isVibrationEnabled, isTrue);
      },
    );

    testWidgets(
      'when system haptic feedback is disabled, vibration switch is automatically off and tapping shows dialog',
      (WidgetTester tester) async {
        const vibrationChannel = MethodChannel('com.timerin.app/vibration');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(vibrationChannel, (
              MethodCall call,
            ) async {
              if (call.method == 'isHapticFeedbackEnabled') return false;
              return true;
            });

        // Initialize repo with vibration enabled
        final repo = TimerSettingsRepository(prefs: prefs);
        await repo.saveSettings(const TimerSettings(isVibrationEnabled: true));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final switchFinder = find.byKey(const Key('vibration_switch'));
        final switchWidget = tester.widget<Switch>(switchFinder);
        // Automatically off
        expect(switchWidget.value, isFalse);
        expect(repo.getSettings().isVibrationEnabled, isFalse);

        // Tapping to turn on shows warning dialog
        await tester.ensureVisible(switchFinder);
        await tester.pumpAndSettle();
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(find.text('Umpan Balik Haptik Belum Aktif'), findsOneWidget);
        expect(find.text('Buka Setelan'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(repo.getSettings().isVibrationEnabled, isFalse);
      },
    );
  });
}
