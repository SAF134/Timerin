import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/overlay/presentation/overlay_permission_dialog.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';

class MockOverlayPermissionService extends Mock
    implements OverlayPermissionService {}

void main() {
  late MockOverlayPermissionService mockPermissionService;

  setUp(() {
    mockPermissionService = MockOverlayPermissionService();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        overlayPermissionServiceProvider.overrideWithValue(
          mockPermissionService,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(body: OverlayPermissionDialog()),
      ),
    );
  }

  group('OverlayPermissionDialog Tests (FR-012 / Restricted Settings)', () {
    testWidgets('renders microcopy and restricted settings guide', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Izin Tampil di Atas Aplikasi'), findsOneWidget);
      expect(
        find.text(
          "Timerin butuh izin 'Tampil di atas aplikasi lain' hanya untuk menampilkan timer di atas game. Timerin tidak membaca layar atau data game kamu.",
        ),
        findsOneWidget,
      );
      expect(
        find.text('Tombol Izin Abu-Abu / Tidak Bisa Ditekan?'),
        findsOneWidget,
      );
      expect(find.text('Buka Info Aplikasi Timerin'), findsOneWidget);
      expect(
        find.text('Ketuk ikon menu 3-titik (⋮) di pojok kanan atas'),
        findsOneWidget,
      );
      expect(
        find.text('Pilih "Izinkan setelan terbatas" & masukkan PIN/sidik jari'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Buka Pengaturan Izin calls requestOverlayPermission', (
      WidgetTester tester,
    ) async {
      when(
        () => mockPermissionService.requestOverlayPermission(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Buka Pengaturan Izin'));
      await tester.pumpAndSettle();

      verify(() => mockPermissionService.requestOverlayPermission()).called(1);
    });

    testWidgets(
      'tapping Buka Setelan Info Aplikasi calls openApplicationSettings',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.openApplicationSettings(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('Buka Setelan Info Aplikasi'));
        await tester.pumpAndSettle();

        verify(() => mockPermissionService.openApplicationSettings()).called(1);
      },
    );
  });
}
