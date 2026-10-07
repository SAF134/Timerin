import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';
import 'package:timerin/features/auth/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUserRepository mockUserRepository;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUserRepository = MockUserRepository();

    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
      userRepository: mockUserRepository,
    );
  });

  group('AuthService Tests (T-002)', () {
    test(
      'signInWithGoogle returns null if user cancels Google sign in',
      () async {
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await authService.signInWithGoogle();

        expect(result, isNull);
        verifyNever(
          () => mockFirebaseAuth.signInWithCredential(any<AuthCredential>()),
        );
      },
    );

    test(
      'signInWithGoogle completes login and creates initial user doc',
      () async {
        final mockGoogleAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockCredential = MockUserCredential();
        final mockUser = MockUser();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleAccount);
        when(
          () => mockGoogleAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('test_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('test_id_token');

        when(
          () => mockFirebaseAuth.signInWithCredential(any<AuthCredential>()),
        ).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('uid_abc');
        when(() => mockUser.email).thenReturn('abc@example.com');
        when(() => mockUser.displayName).thenReturn('ABC');

        when(
          () => mockUserRepository.createInitialUserDocIfNotExists(
            uid: any<String>(named: 'uid'),
            email: any<String>(named: 'email'),
            displayName: any<String>(named: 'displayName'),
          ),
        ).thenAnswer(
          (_) async => const UserModel(
            uid: 'uid_abc',
            email: 'abc@example.com',
            displayName: 'ABC',
          ),
        );
        when(
          () => mockUserRepository.updateLastSeen(any<String>()),
        ).thenAnswer((_) async {});

        final result = await authService.signInWithGoogle();

        expect(result, equals(mockCredential));
        verify(
          () => mockUserRepository.createInitialUserDocIfNotExists(
            uid: 'uid_abc',
            email: 'abc@example.com',
            displayName: 'ABC',
          ),
        ).called(1);
        verify(() => mockUserRepository.updateLastSeen('uid_abc')).called(1);
      },
    );

    test('signOut signs out from GoogleSignIn and FirebaseAuth', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}
