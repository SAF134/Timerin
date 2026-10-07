import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/data/models/app_config_model.dart';
import 'package:timerin/data/repositories/app_config_repository.dart';

class MockAppConfigRepository extends Mock implements AppConfigRepository {}

void main() {
  late MockAppConfigRepository mockRepo;

  setUp(() {
    mockRepo = MockAppConfigRepository();
  });

  group('AppUpdateService Tests (T-018 / FR-020)', () {
    test(
      'returns upToDate when remote config is null (offline/not found)',
      () async {
        when(() => mockRepo.getAppConfig()).thenAnswer((_) async => null);

        final service = AppUpdateService(
          configRepository: mockRepo,
          currentVersionCode: 1,
          currentVersionName: '1.0.0',
        );

        final info = await service.checkUpdate();
        expect(info.type, AppUpdateType.upToDate);
        expect(info.hasUpdate, isFalse);
        expect(info.isForceUpdate, isFalse);
      },
    );

    test('returns force when currentVersionCode < minVersionCode', () async {
      const config = AppConfigModel(
        latestVersionCode: 3,
        latestVersionName: '1.2.0',
        minVersionCode: 2,
        downloadUrl: 'https://drive.google.com/apk-v3',
        releaseNotes: 'Pembaruan keamanan kritis.',
      );
      when(() => mockRepo.getAppConfig()).thenAnswer((_) async => config);

      final service = AppUpdateService(
        configRepository: mockRepo,
        currentVersionCode: 1,
        currentVersionName: '1.0.0',
      );

      final info = await service.checkUpdate();
      expect(info.type, AppUpdateType.force);
      expect(info.hasUpdate, isTrue);
      expect(info.isForceUpdate, isTrue);
      expect(info.downloadUrl, 'https://drive.google.com/apk-v3');
      expect(info.latestVersionName, '1.2.0');
    });

    test(
      'returns optional when currentVersionCode < latestVersionCode and >= minVersionCode',
      () async {
        const config = AppConfigModel(
          latestVersionCode: 2,
          latestVersionName: '1.0.1',
          minVersionCode: 1,
          downloadUrl: 'https://drive.google.com/apk-v2',
          releaseNotes: 'Fitur baru dan perbaikan glitch.',
        );
        when(() => mockRepo.getAppConfig()).thenAnswer((_) async => config);

        final service = AppUpdateService(
          configRepository: mockRepo,
          currentVersionCode: 1,
          currentVersionName: '1.0.0',
        );

        final info = await service.checkUpdate();
        expect(info.type, AppUpdateType.optional);
        expect(info.hasUpdate, isTrue);
        expect(info.isForceUpdate, isFalse);
        expect(info.downloadUrl, 'https://drive.google.com/apk-v2');
      },
    );

    test(
      'returns upToDate when currentVersionCode >= latestVersionCode',
      () async {
        const config = AppConfigModel(
          latestVersionCode: 1,
          latestVersionName: '1.0.0',
          minVersionCode: 1,
          downloadUrl: 'https://drive.google.com/apk-v1',
        );
        when(() => mockRepo.getAppConfig()).thenAnswer((_) async => config);

        final service = AppUpdateService(
          configRepository: mockRepo,
          currentVersionCode: 1,
          currentVersionName: '1.0.0',
        );

        final info = await service.checkUpdate();
        expect(info.type, AppUpdateType.upToDate);
        expect(info.hasUpdate, isFalse);
        expect(info.isForceUpdate, isFalse);
      },
    );
  });
}
