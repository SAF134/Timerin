import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/data/models/user_model.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserRepository(firestore: firestore);
});

class UserRepository {
  UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  /// Mengambil dokumen pengguna berdasarkan [uid].
  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromDocument(snapshot);
  }

  /// Membuat dokumen pengguna baru jika belum pernah dibuat.
  /// Mematuhi aturan keamanan firestore.rules:
  /// - `createdAt = serverTimestamp()`
  /// - `trialStartedAt = null`
  /// - `subscriptionEndsAt = null`
  Future<UserModel> createInitialUserDocIfNotExists({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final docRef = _userDoc(uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromDocument(snapshot);
    }

    final newUser = UserModel(uid: uid, email: email, displayName: displayName);

    await docRef.set(newUser.toInitialCreateMap());
    return newUser;
  }

  /// Memperbarui timestamp aktivitas [lastSeenAt] dengan server timestamp.
  Future<void> updateLastSeen(String uid) async {
    await _userDoc(
      uid,
    ).update(<String, dynamic>{'lastSeenAt': FieldValue.serverTimestamp()});
  }

  /// Mengajukan permintaan penghapusan akun (`deleteRequestedAt`).
  Future<void> requestAccountDeletion(String uid) async {
    await _userDoc(uid).update(<String, dynamic>{
      'deleteRequestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream pembaruan dokumen pengguna secara real-time.
  Stream<UserModel?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromDocument(snapshot);
    });
  }
}
