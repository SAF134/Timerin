import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return AuthService(
    firebaseAuth: firebaseAuth,
    googleSignIn: googleSignIn,
    userRepository: userRepository,
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchUser(user.uid);
});

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required UserRepository userRepository,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _userRepository = userRepository;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Masuk menggunakan akun Google (FR-003).
  /// Menghubungkan kredensial ke Firebase Auth dan otomatis membuat dokumen `users/{uid}`.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // Pengguna membatalkan alur login
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _userRepository.createInitialUserDocIfNotExists(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
      await _userRepository.updateLastSeen(user.uid);
    }

    return userCredential;
  }

  /// Keluar dari sesi akun Google dan Firebase.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
