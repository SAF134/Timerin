import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/overlay/services/overlay_service_controller.dart';

class MockOverlayPermissionService extends Mock
    implements OverlayPermissionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOverlayPermissionService mockPermissionService;
  late OverlayServiceController controller;
  late List<MethodCall> methodCalls;

  const channel = MethodChannel('x-slayer/overlay_channel');

  setUp(() {
    mockPermissionService = MockOverlayPermissionService();
    controller = OverlayServiceController(
      permissionService: mockPermissionService,
    );
    methodCalls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'showOverlay') {
            return null;
          }
          if (call.method == 'closeOverlay') {
            return true;
          }
          if (call.method == 'isOverlayActive') {
            return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('OverlayServiceController Tests (T-006 / FR-012, FR-019)', () {
    test(
      'startOverlay returns false if overlay permission is not granted',
      () async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => false);

        final result = await controller.startOverlay();

        expect(result, isFalse);
        expect(methodCalls.where((c) => c.method == 'showOverlay'), isEmpty);
      },
    );

    test(
      'startOverlay requests notification and opens overlay when permission is granted',
      () async {
        when(
          () => mockPermissionService.isOverlayPermissionGranted(),
        ).thenAnswer((_) async => true);
        when(
          () => mockPermissionService.isNotificationPermissionGranted(),
        ).thenAnswer((_) async => false);
        when(
          () => mockPermissionService.requestNotificationPermission(),
        ).thenAnswer((_) async => true);

        final result = await controller.startOverlay();

        expect(result, isTrue);
        verify(
          () => mockPermissionService.requestNotificationPermission(),
        ).called(1);
        expect(methodCalls.where((c) => c.method == 'showOverlay'), isNotEmpty);
      },
    );

    test('stopOverlay invokes closeOverlay channel method', () async {
      await controller.stopOverlay();

      expect(methodCalls.where((c) => c.method == 'closeOverlay'), isNotEmpty);
    });

    test('isOverlayActive queries isActive channel method', () async {
      final active = await controller.isOverlayActive();

      expect(active, isTrue);
      expect(
        methodCalls.where((c) => c.method == 'isOverlayActive'),
        isNotEmpty,
      );
    });
  });
}
