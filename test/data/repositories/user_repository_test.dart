// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocRef;
  late MockDocumentSnapshot mockSnapshot;
  late UserRepository repository;

  setUp(() {
    registerFallbackValue(const GetOptions());
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any<String>())).thenReturn(mockDocRef);

    repository = UserRepository(firestore: mockFirestore);
  });

  group('UserRepository Tests (T-002)', () {
    test('getUser returns null when document does not exist', () async {
      when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.data()).thenReturn(null);

      final result = await repository.getUser('non_existent_uid');

      expect(result, isNull);
    });

    test('getUser returns UserModel when document exists', () async {
      when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.id).thenReturn('user_123');
      when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
        'email': 'pro@mlbb.com',
        'displayName': 'Pro',
      });

      final result = await repository.getUser('user_123');

      expect(result, isNotNull);
      expect(result!.uid, 'user_123');
      expect(result.email, 'pro@mlbb.com');
      expect(result.displayName, 'Pro');
    });

    test('createInitialUserDocIfNotExists creates doc if not exists', () async {
      when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.data()).thenReturn(null);
      when(
        () => mockDocRef.set(any<Map<String, dynamic>>()),
      ).thenAnswer((_) async {});

      final result = await repository.createInitialUserDocIfNotExists(
        uid: 'user_new',
        email: 'new@mlbb.com',
        displayName: 'New Player',
      );

      expect(result.uid, 'user_new');
      expect(result.email, 'new@mlbb.com');
      verify(() => mockDocRef.set(any<Map<String, dynamic>>())).called(1);
    });

    test(
      'createInitialUserDocIfNotExists does not overwrite existing doc',
      () async {
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.id).thenReturn('user_existing');
        when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
          'email': 'existing@mlbb.com',
          'displayName': 'Existing',
        });

        final result = await repository.createInitialUserDocIfNotExists(
          uid: 'user_existing',
          email: 'ignored@mlbb.com',
          displayName: 'Ignored',
        );

        expect(result.email, 'existing@mlbb.com');
        verifyNever(() => mockDocRef.set(any<Map<String, dynamic>>()));
      },
    );

    test('updateLastSeen updates document with serverTimestamp', () async {
      when(
        () => mockDocRef.update(any<Map<String, dynamic>>()),
      ).thenAnswer((_) async {});

      await repository.updateLastSeen('user_123');

      verify(() => mockDocRef.update(any<Map<String, dynamic>>())).called(1);
    });

    test('syncServerTime writes lastSeenAt and reads back timestamp', () async {
      final now = DateTime(2026, 10, 7, 15, 0);
      when(
        () => mockDocRef.update(any<Map<String, dynamic>>()),
      ).thenAnswer((_) async {});
      when(
        () => mockDocRef.get(any<GetOptions>()),
      ).thenAnswer((_) async => mockSnapshot);
      when(
        () => mockSnapshot.data(),
      ).thenReturn(<String, dynamic>{'lastSeenAt': Timestamp.fromDate(now)});

      final result = await repository.syncServerTime('user_123');

      expect(result, equals(now));
      verify(() => mockDocRef.update(any<Map<String, dynamic>>())).called(1);
      verify(() => mockDocRef.get(any<GetOptions>())).called(1);
    });

    test('startTrial executes transaction and writes trialStartedAt', () async {
      when(() => mockFirestore.runTransaction<UserModel>(any())).thenAnswer((
        invocation,
      ) async {
        final tx =
            invocation.positionalArguments[0]
                as Future<UserModel> Function(Transaction);
        final mockTx = MockTransaction();
        when(
          () => mockTx.get(mockDocRef),
        ).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
          'email': 'pemain@mlbb.com',
          'displayName': 'Pemain',
          'trialStartedAt': null,
        });
        when(
          () => mockTx.update(mockDocRef, any<Map<String, dynamic>>()),
        ).thenReturn(mockTx);
        return tx(mockTx);
      });

      final user = await repository.startTrial('user_123');

      expect(user.uid, 'user_123');
      expect(user.trialStartedAt, isNotNull);
      verify(() => mockFirestore.runTransaction<UserModel>(any())).called(1);
    });

    test(
      'startTrial throws StateError if trial was already started (anti-reset)',
      () async {
        when(() => mockFirestore.runTransaction<UserModel>(any())).thenAnswer((
          invocation,
        ) async {
          final tx =
              invocation.positionalArguments[0]
                  as Future<UserModel> Function(Transaction);
          final mockTx = MockTransaction();
          when(
            () => mockTx.get(mockDocRef),
          ).thenAnswer((_) async => mockSnapshot);
          when(() => mockSnapshot.exists).thenReturn(true);
          when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
            'email': 'pemain@mlbb.com',
            'displayName': 'Pemain',
            'trialStartedAt': Timestamp.now(),
          });
          return tx(mockTx);
        });

        expect(
          () => repository.startTrial('user_123'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'startTrial throws StateError if user document does not exist',
      () async {
        when(() => mockFirestore.runTransaction<UserModel>(any())).thenAnswer((
          invocation,
        ) async {
          final tx =
              invocation.positionalArguments[0]
                  as Future<UserModel> Function(Transaction);
          final mockTx = MockTransaction();
          when(
            () => mockTx.get(mockDocRef),
          ).thenAnswer((_) async => mockSnapshot);
          when(() => mockSnapshot.exists).thenReturn(false);
          when(() => mockSnapshot.data()).thenReturn(null);
          return tx(mockTx);
        });

        expect(
          () => repository.startTrial('non_existent_uid'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('requestAccountDeletion writes deleteRequestedAt', () async {
      when(
        () => mockDocRef.update(any<Map<String, dynamic>>()),
      ).thenAnswer((_) async {});

      await repository.requestAccountDeletion('user_123');

      verify(
        () => mockDocRef.update(
          any<Map<String, dynamic>>(
            that: containsPair('deleteRequestedAt', isA<FieldValue>()),
          ),
        ),
      ).called(1);
    });

    test('watchUser emits UserModel stream on snapshots', () async {
      when(() => mockDocRef.snapshots()).thenAnswer((_) {
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.id).thenReturn('user_123');
        when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
          'email': 'stream@mlbb.com',
          'displayName': 'Stream Player',
        });
        return Stream.value(mockSnapshot);
      });

      final stream = repository.watchUser('user_123');
      final emittedUser = await stream.first;

      expect(emittedUser, isNotNull);
      expect(emittedUser!.uid, 'user_123');
      expect(emittedUser.email, 'stream@mlbb.com');
    });
  });
}
