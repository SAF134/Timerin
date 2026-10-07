// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timerin/data/repositories/app_config_repository.dart';

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
  late AppConfigRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection('config')).thenReturn(mockCollection);
    when(() => mockCollection.doc('app')).thenReturn(mockDocRef);

    repository = AppConfigRepository(firestore: mockFirestore);
  });

  group('AppConfigRepository Tests (T-018 / FR-020, TECH §4, 6)', () {
    test('getAppConfig returns null when document does not exist', () async {
      when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.data()).thenReturn(null);

      final result = await repository.getAppConfig();
      expect(result, isNull);
    });

    test('getAppConfig returns AppConfigModel when document exists', () async {
      when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
        'latestVersionCode': 3,
        'latestVersionName': '1.1.0',
        'minVersionCode': 2,
        'downloadUrl': 'https://drive.google.com/test-apk',
        'releaseNotes': 'Fitur baru!',
      });

      final result = await repository.getAppConfig();
      expect(result, isNotNull);
      expect(result!.latestVersionCode, 3);
      expect(result.latestVersionName, '1.1.0');
      expect(result.minVersionCode, 2);
      expect(result.downloadUrl, 'https://drive.google.com/test-apk');
      expect(result.releaseNotes, 'Fitur baru!');
    });

    test(
      'getAppConfig returns null on network or firestore exception',
      () async {
        when(() => mockDocRef.get()).thenThrow(
          FirebaseException(plugin: 'firestore', message: 'Network offline'),
        );

        final result = await repository.getAppConfig();
        expect(result, isNull);
      },
    );

    test('watchAppConfig emits AppConfigModel stream', () async {
      when(() => mockDocRef.snapshots()).thenAnswer((_) {
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
          'latestVersionCode': 4,
          'latestVersionName': '1.2.0',
          'minVersionCode': 2,
          'downloadUrl': 'https://drive.google.com/test-apk-4',
        });
        return Stream.value(mockSnapshot);
      });

      final stream = repository.watchAppConfig();
      final config = await stream.first;

      expect(config, isNotNull);
      expect(config!.latestVersionCode, 4);
      expect(config.latestVersionName, '1.2.0');
    });
  });
}
