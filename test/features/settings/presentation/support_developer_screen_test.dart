import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/qris_share_service.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/settings/presentation/support_developer_screen.dart';

class MockQrisShareService extends Mock implements QrisShareService {}

void main() {
  group('SupportDeveloperScreen Tests', () {
    late MockQrisShareService mockQrisShareService;

    setUp(() {
      mockQrisShareService = MockQrisShareService();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          qrisShareServiceProvider.overrideWithValue(mockQrisShareService),
        ],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: const SupportDeveloperScreen(),
        ),
      );
    }

    testWidgets('renders QRIS title, image, and action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Dukung Pengembang'), findsWidgets);
      expect(
        find.textContaining('dukungan tip/donasi sukarela sangat membantu'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('save_qris_developer_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('share_qris_developer_button')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('tapping Simpan QRIS invokes saveQrisToGallery', (
      WidgetTester tester,
    ) async {
      when(
        () => mockQrisShareService.saveQrisToGallery(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final saveBtn = find.byKey(const Key('save_qris_developer_button'));
      await tester.tap(saveBtn);
      await tester.pump();

      verify(() => mockQrisShareService.saveQrisToGallery()).called(1);
      expect(find.textContaining('berhasil disimpan'), findsOneWidget);
    });

    testWidgets('tapping Bagikan QRIS invokes shareQris', (
      WidgetTester tester,
    ) async {
      when(
        () => mockQrisShareService.shareQris(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final shareBtn = find.byKey(const Key('share_qris_developer_button'));
      await tester.tap(shareBtn);
      await tester.pump();

      verify(() => mockQrisShareService.shareQris()).called(1);
    });
  });
}
