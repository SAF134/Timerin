import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/data/models/user_model.dart';

void main() {
  group('UserModel Tests (T-002)', () {
    test(
      'toInitialCreateMap adheres strictly to firestore.rules specification',
      () {
        const user = UserModel(
          uid: 'user_123',
          email: 'player@example.com',
          displayName: 'ProPlayer',
        );

        final map = user.toInitialCreateMap();

        // Rule: keys().hasOnly(['email','displayName','createdAt','trialStartedAt','subscriptionEndsAt','lastSeenAt','deleteRequestedAt'])
        const allowedKeys = <String>{
          'email',
          'displayName',
          'createdAt',
          'trialStartedAt',
          'subscriptionEndsAt',
          'lastSeenAt',
          'deleteRequestedAt',
        };

        expect(map.keys.toSet(), allowedKeys);
        expect(map['email'], 'player@example.com');
        expect(map['displayName'], 'ProPlayer');
        expect(map['trialStartedAt'], isNull);
        expect(map['subscriptionEndsAt'], isNull);
        expect(map['deleteRequestedAt'], isNull);
        expect(map['createdAt'], isA<FieldValue>());
        expect(map['lastSeenAt'], isA<FieldValue>());
      },
    );

    test('fromMap parses Timestamp and DateTime correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final map = <String, dynamic>{
        'email': 'player@example.com',
        'displayName': 'ProPlayer',
        'createdAt': timestamp,
        'trialStartedAt': timestamp,
        'subscriptionEndsAt': now,
        'lastSeenAt': timestamp,
        'deleteRequestedAt': null,
      };

      final model = UserModel.fromMap('user_123', map);

      expect(model.uid, 'user_123');
      expect(model.email, 'player@example.com');
      expect(model.displayName, 'ProPlayer');
      expect(model.createdAt, now);
      expect(model.trialStartedAt, now);
      expect(model.subscriptionEndsAt, now);
      expect(model.lastSeenAt, now);
      expect(model.deleteRequestedAt, isNull);
    });

    test('copyWith updates fields as expected and equality holds', () {
      const user = UserModel(
        uid: 'user_123',
        email: 'old@example.com',
        displayName: 'Old',
      );

      final updated = user.copyWith(
        email: 'new@example.com',
        displayName: 'New',
      );

      expect(updated.email, 'new@example.com');
      expect(updated.displayName, 'New');
      expect(updated.uid, 'user_123');

      final copy = user.copyWith();
      expect(copy, equals(user));
    });
  });
}
