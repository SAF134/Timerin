import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/services/url_launcher_service.dart';

void main() {
  group('UrlLauncherService Tests', () {
    test('provider provides DefaultUrlLauncherService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(urlLauncherServiceProvider);
      expect(service, isA<DefaultUrlLauncherService>());
    });

    test('launchExternalUrl returns false on invalid URL string', () async {
      const service = DefaultUrlLauncherService();
      // An empty or unparseable uri cannot be launched in headless test environment
      final result = await service.launchExternalUrl('');
      expect(result, isFalse);
    });
  });
}
