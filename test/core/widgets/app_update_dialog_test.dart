import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/core/widgets/app_update_dialog.dart';

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  late MockUrlLauncherService mockLauncher;

  setUp(() {
    mockLauncher = MockUrlLauncherService();
  });

  Widget createWidgetUnderTest(AppUpdateInfo info) {
    return ProviderScope(
      overrides: [urlLauncherServiceProvider.overrideWithValue(mockLauncher)],
      child: MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('open_dialog_button'),
                onPressed: () => AppUpdateDialog.show(context, info),
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('AppUpdateDialog Widget Tests (T-018 / FR-020, SECURITY §3)', () {
    testWidgets(
      'renders optional update dialog with release notes, action, and later buttons',
      (WidgetTester tester) async {
        const info = AppUpdateInfo(
          type: AppUpdateType.optional,
          currentVersionCode: 1,
          currentVersionName: '1.0.0',
          latestVersionCode: 2,
          latestVersionName: '1.1.0',
          minVersionCode: 1,
          downloadUrl: 'https://drive.google.com/test-download',
          releaseNotes: 'Fitur baru cooldown spell.',
        );

        when(
          () => mockLauncher.launchExternalUrl(
            'https://drive.google.com/test-download',
          ),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest(info));
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        expect(find.text('Pembaruan Aplikasi Tersedia'), findsOneWidget);
        expect(find.textContaining('1.1.0'), findsWidgets);
        expect(find.text('Fitur baru cooldown spell.'), findsOneWidget);
        expect(
          find.byKey(const Key('update_dialog_action_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('update_dialog_later_button')),
          findsOneWidget,
        );

        // Tap action button
        await tester.tap(find.byKey(const Key('update_dialog_action_button')));
        await tester.pumpAndSettle();

        verify(
          () => mockLauncher.launchExternalUrl(
            'https://drive.google.com/test-download',
          ),
        ).called(1);

        // Tap later button
        await tester.tap(find.byKey(const Key('update_dialog_later_button')));
        await tester.pumpAndSettle();

        expect(find.text('Pembaruan Aplikasi Tersedia'), findsNothing);
      },
    );

    testWidgets('renders force update dialog without later button', (
      WidgetTester tester,
    ) async {
      const info = AppUpdateInfo(
        type: AppUpdateType.force,
        currentVersionCode: 1,
        currentVersionName: '1.0.0',
        latestVersionCode: 3,
        latestVersionName: '1.2.0',
        minVersionCode: 2,
        downloadUrl: 'https://drive.google.com/test-force',
        releaseNotes: 'Pembaruan keamanan mendesak.',
      );

      await tester.pumpWidget(createWidgetUnderTest(info));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Wajib Tersedia'), findsOneWidget);
      expect(
        find.byKey(const Key('update_dialog_action_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('update_dialog_later_button')), findsNothing);
    });
  });
}
