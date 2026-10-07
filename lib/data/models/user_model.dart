import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model pengguna Timerin untuk koleksi `users/{uid}` sesuai `docs/03-TECH.md` §4.
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.trialStartedAt,
    this.subscriptionEndsAt,
    this.lastSeenAt,
    this.deleteRequestedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final DateTime? createdAt;
  final DateTime? trialStartedAt;
  final DateTime? subscriptionEndsAt;
  final DateTime? lastSeenAt;
  final DateTime? deleteRequestedAt;

  /// Payload pembuatan dokumen awal pertama kali yang mematuhi `firestore.rules`.
  /// Aturan mewajibkan:
  /// - `createdAt == request.time`
  /// - `trialStartedAt == null`
  /// - `subscriptionEndsAt == null`
  /// - keys hanya boleh: email, displayName, createdAt, trialStartedAt, subscriptionEndsAt, lastSeenAt, deleteRequestedAt.
  Map<String, dynamic> toInitialCreateMap() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'trialStartedAt': null,
      'subscriptionEndsAt': null,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'deleteRequestedAt': null,
    };
  }

  /// Membaca dokumen dari data Firestore.
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      trialStartedAt: parseTimestamp(data['trialStartedAt']),
      subscriptionEndsAt: parseTimestamp(data['subscriptionEndsAt']),
      lastSeenAt: parseTimestamp(data['lastSeenAt']),
      deleteRequestedAt: parseTimestamp(data['deleteRequestedAt']),
    );
  }

  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return UserModel.fromMap(snapshot.id, data);
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? trialStartedAt,
    DateTime? subscriptionEndsAt,
    DateTime? lastSeenAt,
    DateTime? deleteRequestedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      deleteRequestedAt: deleteRequestedAt ?? this.deleteRequestedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.trialStartedAt == trialStartedAt &&
        other.subscriptionEndsAt == subscriptionEndsAt &&
        other.lastSeenAt == lastSeenAt &&
        other.deleteRequestedAt == deleteRequestedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      createdAt,
      trialStartedAt,
      subscriptionEndsAt,
      lastSeenAt,
      deleteRequestedAt,
    );
  }
}
