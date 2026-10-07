import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/constants/app_constants.dart';
import 'package:timerin/data/repositories/app_config_repository.dart';

/// Jenis ketersediaan pembaruan aplikasi (FR-020).
enum AppUpdateType {
  /// Versi aplikasi saat ini sudah paling baru.
  upToDate,

  /// Tersedia versi baru opsional yang dapat ditunda oleh pengguna.
  optional,

  /// Versi aplikasi berada di bawah batas minimum dan wajib diperbarui (force update).
  force,
}

/// Informasi hasil pengecekan pembaruan aplikasi.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.type,
    required this.currentVersionCode,
    required this.currentVersionName,
    this.latestVersionCode,
    this.latestVersionName,
    this.minVersionCode,
    this.downloadUrl,
    this.releaseNotes,
  });

  final AppUpdateType type;
  final int currentVersionCode;
  final String currentVersionName;
  final int? latestVersionCode;
  final String? latestVersionName;
  final int? minVersionCode;
  final String? downloadUrl;
  final String? releaseNotes;

  /// Apakah ada versi baru yang tersedia.
  bool get hasUpdate => type != AppUpdateType.upToDate;

  /// Apakah pembaruan ini bersifat wajib / force update.
  bool get isForceUpdate => type == AppUpdateType.force;
}

/// Layanan evaluasi versi aplikasi terhadap konfigurasi `config/app` (FR-020, TECH §4, 6).
class AppUpdateService {
  AppUpdateService({
    required AppConfigRepository configRepository,
    int currentVersionCode = AppConstants.currentVersionCode,
    String currentVersionName = AppConstants.currentVersionName,
  }) : _configRepository = configRepository,
       _currentVersionCode = currentVersionCode,
       _currentVersionName = currentVersionName;

  final AppConfigRepository _configRepository;
  final int _currentVersionCode;
  final String _currentVersionName;

  /// Memeriksa ketersediaan pembaruan dari Firestore.
  Future<AppUpdateInfo> checkUpdate() async {
    final config = await _configRepository.getAppConfig();
    if (config == null) {
      return AppUpdateInfo(
        type: AppUpdateType.upToDate,
        currentVersionCode: _currentVersionCode,
        currentVersionName: _currentVersionName,
      );
    }

    // Force update jika versi terpasang < minVersionCode
    if (_currentVersionCode < config.minVersionCode) {
      return AppUpdateInfo(
        type: AppUpdateType.force,
        currentVersionCode: _currentVersionCode,
        currentVersionName: _currentVersionName,
        latestVersionCode: config.latestVersionCode,
        latestVersionName: config.latestVersionName,
        minVersionCode: config.minVersionCode,
        downloadUrl: config.downloadUrl,
        releaseNotes: config.releaseNotes,
      );
    }

    // Optional update jika versi terpasang < latestVersionCode
    if (_currentVersionCode < config.latestVersionCode) {
      return AppUpdateInfo(
        type: AppUpdateType.optional,
        currentVersionCode: _currentVersionCode,
        currentVersionName: _currentVersionName,
        latestVersionCode: config.latestVersionCode,
        latestVersionName: config.latestVersionName,
        minVersionCode: config.minVersionCode,
        downloadUrl: config.downloadUrl,
        releaseNotes: config.releaseNotes,
      );
    }

    return AppUpdateInfo(
      type: AppUpdateType.upToDate,
      currentVersionCode: _currentVersionCode,
      currentVersionName: _currentVersionName,
      latestVersionCode: config.latestVersionCode,
      latestVersionName: config.latestVersionName,
      minVersionCode: config.minVersionCode,
      downloadUrl: config.downloadUrl,
      releaseNotes: config.releaseNotes,
    );
  }
}

/// Provider untuk [AppUpdateService].
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final repo = ref.watch(appConfigRepositoryProvider);
  return AppUpdateService(configRepository: repo);
});
