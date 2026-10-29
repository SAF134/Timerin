import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/services/qris_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrisShareService Tests', () {
    const channel = MethodChannel('com.timerin.app/vibration');
    late QrisShareService service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = const QrisShareService();
      methodCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            methodCalls.add(call);
            if (call.method == 'shareQris' || call.method == 'saveQris') {
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('shareQris invokes shareQris on channel and returns true', () async {
      final result = await service.shareQris();
      expect(result, isTrue);
      expect(methodCalls.map((c) => c.method), contains('shareQris'));
    });

    test(
      'saveQrisToGallery invokes saveQris on channel and returns true',
      () async {
        final result = await service.saveQrisToGallery();
        expect(result, isTrue);
        expect(methodCalls.map((c) => c.method), contains('saveQris'));
      },
    );
  });
}
