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

  /// Memperbarui [lastSeenAt] dan mengambil timestamp server resmi (TECH §5 item 1).
  Future<DateTime> syncServerTime(String uid) async {
    final docRef = _userDoc(uid);
    await docRef.update(<String, dynamic>{
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
    final snapshot = await docRef.get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data != null && data['lastSeenAt'] is Timestamp) {
      return (data['lastSeenAt'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  /// Memulai masa trial 24 jam secara atomik (FR-013, TECH §5 item 5).
  /// Memastikan `trialStartedAt` hanya ditulis sekali seumur hidup akun.
  Future<UserModel> startTrial(String uid) async {
    final docRef = _userDoc(uid);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Pengguna tidak ditemukan');
      }
      final data = snapshot.data()!;
      if (data['trialStartedAt'] != null) {
        throw StateError('Trial sudah pernah dimulai');
      }

      transaction.update(docRef, <String, dynamic>{
        'trialStartedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });

      final updatedData = Map<String, dynamic>.from(data);
      updatedData['trialStartedAt'] = Timestamp.now();
      updatedData['lastSeenAt'] = Timestamp.now();
      return UserModel.fromMap(uid, updatedData);
    });
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
