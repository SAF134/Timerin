import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/settings/presentation/about_developer_screen.dart';

void main() {
  group('AboutDeveloperScreen Tests', () {
    testWidgets(
      'renders developer image, bio, contact, and QRIS, without security card',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            home: const AboutDeveloperScreen(),
          ),
        );
        await tester.pump();

        expect(find.text('Tentang Pengembang'), findsOneWidget);
        expect(
          find.text('Halo! Saya pengembang aplikasi Timerin.'),
          findsOneWidget,
        );
        expect(find.text('Kontak Pengembang'), findsOneWidget);
        expect(find.text('timerindev@gmail.com'), findsOneWidget);
        expect(find.text('Dukung Pengembang'), findsOneWidget);
        expect(find.byType(Image), findsWidgets);

        // Kartu Jaminan Keamanan Aplikasi dihapus sesuai permintaan
        expect(find.text('Jaminan Keamanan Aplikasi'), findsNothing);
        expect(find.text('Tanpa Modifikasi & Tanpa Cheat'), findsNothing);
      },
    );
  });
}
