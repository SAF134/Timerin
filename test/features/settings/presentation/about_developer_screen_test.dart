import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/settings/presentation/about_developer_screen.dart';

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  late MockUrlLauncherService mockLauncher;

  setUp(() {
    mockLauncher = MockUrlLauncherService();
  });

  group('AboutDeveloperScreen Tests', () {
    testWidgets(
      'renders developer image, bio, contact, website card, and support navigation button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              urlLauncherServiceProvider.overrideWithValue(mockLauncher),
            ],
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const AboutDeveloperScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Tentang Pengembang'), findsOneWidget);
        expect(
          find.text('Halo! Saya SAF, Pengembang Aplikasi Timerin.'),
          findsOneWidget,
        );
        expect(find.text('Kontak Pengembang'), findsOneWidget);
        expect(find.byKey(const Key('developer_email_button')), findsOneWidget);
        expect(find.text('timerindev@gmail.com'), findsOneWidget);

        // Website Resmi & Unduhan Card
        expect(find.text('Website Resmi & Unduhan'), findsOneWidget);
        expect(
          find.textContaining('Unduh versi APK terbaru Timerin'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('developer_website_button')),
          findsOneWidget,
        );
        expect(find.text('timerin.vercel.app'), findsOneWidget);

        expect(find.text('Dukung Pengembang'), findsOneWidget);
        expect(
          find.byKey(const Key('open_support_developer_button')),
          findsOneWidget,
        );
        expect(find.byType(Image), findsWidgets);

        // Kartu Jaminan Keamanan Aplikasi dihapus sesuai permintaan
        expect(find.text('Jaminan Keamanan Aplikasi'), findsNothing);
        expect(find.text('Tanpa Modifikasi & Tanpa Cheat'), findsNothing);
      },
    );

    testWidgets(
      'tapping website button calls launchExternalUrl with timerin vercel url',
      (WidgetTester tester) async {
        when(
          () => mockLauncher.launchExternalUrl('https://timerin.vercel.app/'),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              urlLauncherServiceProvider.overrideWithValue(mockLauncher),
            ],
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const AboutDeveloperScreen(),
            ),
          ),
        );
        await tester.pump();

        final webBtn = find.byKey(const Key('developer_website_button'));
        await tester.ensureVisible(webBtn);
        await tester.pumpAndSettle();
        await tester.tap(webBtn);
        await tester.pumpAndSettle();

        verify(
          () => mockLauncher.launchExternalUrl('https://timerin.vercel.app/'),
        ).called(1);
      },
    );
  });
}
