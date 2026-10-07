import 'package:cloud_firestore/cloud_firestore.dart';

/// Model konfigurasi publik aplikasi dari Firestore `config/app` (FR-020, TECH §4, 6).
class AppConfigModel {
  const AppConfigModel({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.minVersionCode,
    required this.downloadUrl,
    this.releaseNotes,
  });

  /// Versi kode aplikasi terbaru yang dirilis oleh developer (misal: 2).
  final int latestVersionCode;

  /// Nama versi terbaru (misal: "1.1.0").
  final String latestVersionName;

  /// Versi kode minimal yang didukung; versi di bawah ini memicu force update (misal: 1).
  final int minVersionCode;

  /// Tautan publik pengunduhan APK resmi (misal: Google Drive publik).
  final String downloadUrl;

  /// Catatan rilis / pembaruan fitur (opsional).
  final String? releaseNotes;

  /// Membaca konfigurasi dari snapshot Firestore `config/app`.
  factory AppConfigModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppConfigModel.fromMap(data);
  }

  /// Membaca konfigurasi dari Map.
  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      latestVersionCode: (map['latestVersionCode'] as num?)?.toInt() ?? 1,
      latestVersionName: (map['latestVersionName'] as String?) ?? '1.0.0',
      minVersionCode: (map['minVersionCode'] as num?)?.toInt() ?? 1,
      downloadUrl: (map['downloadUrl'] as String?) ?? '',
      releaseNotes: map['releaseNotes'] as String?,
    );
  }

  /// Mengonversi ke Map untuk keperluan Firestore / pengujian.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latestVersionCode': latestVersionCode,
      'latestVersionName': latestVersionName,
      'minVersionCode': minVersionCode,
      'downloadUrl': downloadUrl,
      if (releaseNotes != null) 'releaseNotes': releaseNotes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfigModel &&
        other.latestVersionCode == latestVersionCode &&
        other.latestVersionName == latestVersionName &&
        other.minVersionCode == minVersionCode &&
        other.downloadUrl == downloadUrl &&
        other.releaseNotes == releaseNotes;
  }

  @override
  int get hashCode => Object.hash(
    latestVersionCode,
    latestVersionName,
    minVersionCode,
    downloadUrl,
    releaseNotes,
  );
}
