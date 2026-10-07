// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/data/repositories/user_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocRef;
  late MockDocumentSnapshot mockSnapshot;
  late UserRepository repository;

  setUp(() {
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
  });
}
