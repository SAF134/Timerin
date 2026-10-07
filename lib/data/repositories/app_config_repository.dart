import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/data/models/app_config_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';

/// Provider untuk [AppConfigRepository].
final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AppConfigRepository(firestore: firestore);
});

/// Repositori pembaca konfigurasi publik aplikasi dari Firestore `config/app` (FR-020, TECH §4, 6).
class AppConfigRepository {
  AppConfigRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('config').doc('app');

  /// Mengambil data konfigurasi aplikasi publik dari Firestore `config/app`.
  /// Mengembalikan `null` jika dokumen belum tersedia atau terjadi kegagalan jaringan.
  Future<AppConfigModel?> getAppConfig() async {
    try {
      final snapshot = await _configDoc.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AppConfigModel.fromDocument(snapshot);
    } catch (_) {
      return null;
    }
  }

  /// Memantau perubahan konfigurasi aplikasi secara real-time.
  Stream<AppConfigModel?> watchAppConfig() {
    return _configDoc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AppConfigModel.fromDocument(snapshot);
    });
  }
}
