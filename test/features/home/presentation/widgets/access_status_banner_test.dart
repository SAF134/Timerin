import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/home/presentation/widgets/access_status_banner.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';

void main() {
  Widget buildBanner({
    required AccessState accessState,
    VoidCallback? onSubscribePressed,
  }) {
    return MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: AccessStatusBanner(
          accessState: accessState,
          onSubscribePressed: onSubscribePressed,
        ),
      ),
    );
  }

  group('AccessStatusBanner Tests (SCR-004, FR-004, FR-014)', () {
    testWidgets('renders BARU status banner correctly', (
      WidgetTester tester,
    ) async {
      const state = AccessState(
        status: AccessStatus.baru,
        remainingAccess: Duration.zero,
      );

      await tester.pumpWidget(buildBanner(accessState: state));

      expect(find.text('Trial 24 Jam'), findsOneWidget);
      expect(find.text('Siap Dimulai'), findsOneWidget);
      expect(
        find.text(
          'Trial 24 jam gratis siap dimulai saat kamu mengaktifkan overlay pertama kali.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('banner_subscribe_button')), findsNothing);
      expect(find.text('Segarkan Status'), findsNothing);
    });

    testWidgets(
      'renders TRIAL status banner and triggers onSubscribePressed on tap',
      (WidgetTester tester) async {
        bool subscribeTapped = false;
        const state = AccessState(
          status: AccessStatus.trial,
          remainingAccess: Duration(hours: 18),
        );

        await tester.pumpWidget(
          buildBanner(
            accessState: state,
            onSubscribePressed: () => subscribeTapped = true,
          ),
        );

        expect(find.text('Masa Coba Gratis'), findsOneWidget);
        expect(find.text('sisa 18 jam'), findsOneWidget);
        expect(
          find.text(
            'Masa coba gratis sedang aktif (sisa 18 jam). Akses penuh seluruh fitur overlay.',
          ),
          findsOneWidget,
        );

        final button = find.byKey(const Key('banner_subscribe_button'));
        expect(button, findsOneWidget);
        expect(find.text('Perpanjang Langganan'), findsOneWidget);

        await tester.tap(button);
        await tester.pump();

        expect(subscribeTapped, isTrue);
      },
    );

    testWidgets('renders BERLANGGANAN status banner correctly', (
      WidgetTester tester,
    ) async {
      const state = AccessState(
        status: AccessStatus.berlangganan,
        remainingAccess: Duration(days: 28),
      );

      await tester.pumpWidget(buildBanner(accessState: state));

      expect(find.text('Status Berlangganan'), findsOneWidget);
      expect(find.text('Aktif (sisa 28 hari)'), findsOneWidget);
      expect(
        find.text('Status Berlangganan: Aktif (sisa 28 hari).'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('banner_subscribe_button')), findsNothing);
    });

    testWidgets(
      'renders HABIS status banner and triggers onSubscribePressed on tap (FR-014)',
      (WidgetTester tester) async {
        bool subscribeTapped = false;
        const state = AccessState(
          status: AccessStatus.habis,
          remainingAccess: Duration.zero,
        );

        await tester.pumpWidget(
          buildBanner(
            accessState: state,
            onSubscribePressed: () => subscribeTapped = true,
          ),
        );

        expect(find.text('Masa Aktif Habis'), findsOneWidget);
        expect(find.text('Habis'), findsOneWidget);
        expect(
          find.text(
            'Trial 24 jam selesai. Berlangganan Rp10.000/bulan untuk lanjut memakai timer.',
          ),
          findsOneWidget,
        );

        final button = find.byKey(const Key('banner_subscribe_button'));
        expect(button, findsOneWidget);
        expect(find.text('Perpanjang Langganan'), findsOneWidget);

        await tester.tap(button);
        await tester.pump();

        expect(subscribeTapped, isTrue);
      },
    );
  });
}
