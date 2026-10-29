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

  group('OverlayPermissionDialog Tests (FR-012)', () {
    testWidgets('renders microcopy and permission action buttons', (
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
      expect(find.text('Buka Setelan Izin Sistem'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
    });

    testWidgets(
      'tapping Buka Setelan Izin Sistem calls requestOverlayPermission',
      (WidgetTester tester) async {
        when(
          () => mockPermissionService.requestOverlayPermission(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('Buka Setelan Izin Sistem'));
        await tester.pumpAndSettle();

        verify(
          () => mockPermissionService.requestOverlayPermission(),
        ).called(1);
      },
    );

    testWidgets('renders Nanti Saja as an OutlinedButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final laterButton = find.widgetWithText(OutlinedButton, 'Nanti Saja');
      expect(laterButton, findsOneWidget);
    });
  });
}
