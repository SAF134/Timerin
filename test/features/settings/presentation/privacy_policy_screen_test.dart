import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/settings/presentation/privacy_policy_screen.dart';

void main() {
  group('PrivacyPolicyScreen Tests', () {
    testWidgets('renders all privacy policy sections and information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.theme, home: const PrivacyPolicyScreen()),
      );
      await tester.pump();

      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Komitmen Privasi & Keamanan'), findsOneWidget);
      expect(
        find.textContaining('Kebijakan Privasi Aplikasi Timerin'),
        findsOneWidget,
      );
      expect(
        find.textContaining('1. Autentikasi & Keamanan Akun Google'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2. Keamanan Game & Bebas Risiko Ban'),
        findsOneWidget,
      );
      expect(
        find.textContaining('3. Transparansi Izin Sistem Android'),
        findsOneWidget,
      );
      expect(
        find.textContaining('4. Penyimpanan Data & Bebas Penjualan Data'),
        findsOneWidget,
      );
      expect(
        find.textContaining('5. Hak Pengguna & Mode Privasi'),
        findsOneWidget,
      );
      expect(find.textContaining('6. Kontak Pengembang Resmi'), findsOneWidget);
      expect(find.textContaining('timerindev@gmail.com'), findsOneWidget);
    });
  });
}
