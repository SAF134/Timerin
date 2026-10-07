import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/data/models/app_config_model.dart';

void main() {
  group('AppConfigModel Tests (T-018 / FR-020, TECH §4, 6)', () {
    test('fromMap creates valid AppConfigModel with default fallbacks', () {
      final model = AppConfigModel.fromMap(const <String, dynamic>{});

      expect(model.latestVersionCode, 1);
      expect(model.latestVersionName, '1.0.0');
      expect(model.minVersionCode, 1);
      expect(model.downloadUrl, isEmpty);
      expect(model.releaseNotes, isNull);
    });

    test('fromMap and toMap serialize all properties correctly', () {
      const original = AppConfigModel(
        latestVersionCode: 5,
        latestVersionName: '1.2.0',
        minVersionCode: 3,
        downloadUrl: 'https://drive.google.com/apk/timerin-v1.2.0.apk',
        releaseNotes: 'Optimasi performa floating timer dan perbaikan bug.',
      );

      final map = original.toMap();
      expect(map['latestVersionCode'], 5);
      expect(map['latestVersionName'], '1.2.0');
      expect(map['minVersionCode'], 3);
      expect(
        map['downloadUrl'],
        'https://drive.google.com/apk/timerin-v1.2.0.apk',
      );
      expect(map['releaseNotes'], contains('Optimasi'));

      final reconstructed = AppConfigModel.fromMap(map);
      expect(reconstructed, equals(original));
      expect(reconstructed.hashCode, equals(original.hashCode));
    });
  });
}
