import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
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

    test(
      'calculateWindowDimensions computes compact size based on orientation and scale',
      () {
        const verticalSettings = TimerSettings(
          timerCount: 3,
          orientation: TimerOrientation.vertical,
          scale: 1.0,
        );
        final verticalDims = OverlayServiceController.calculateWindowDimensions(
          verticalSettings,
        );
        expect(verticalDims.width, 84); // (56 + 28)
        expect(verticalDims.height, 216); // (3*56 + 2*8 + 32)

        const horizontalSettings = TimerSettings(
          timerCount: 3,
          orientation: TimerOrientation.horizontal,
          scale: 1.0,
        );
        final horizontalDims =
            OverlayServiceController.calculateWindowDimensions(
              horizontalSettings,
            );
        expect(horizontalDims.width, 216);
        expect(horizontalDims.height, 84);
      },
    );

    test('updateDimensions invokes resizeOverlay on overlay channel', () async {
      const overlayChannel = MethodChannel('x-slayer/overlay');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(overlayChannel, (MethodCall call) async {
            methodCalls.add(call);
            return true;
          });

      const settings = TimerSettings(timerCount: 2);
      await controller.updateDimensions(settings);

      expect(methodCalls.where((c) => c.method == 'resizeOverlay'), isNotEmpty);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(overlayChannel, null);
    });
  });
}
