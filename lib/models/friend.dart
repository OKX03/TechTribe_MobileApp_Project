import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String uid;
  final String username;
  final String profilePicture;
  final Timestamp? since;

  Friend({
    required this.uid,
    required this.username,
    required this.profilePicture,
    this.since,
  });

  factory Friend.fromMap(Map<String, dynamic> map, String id) {
    return Friend(
      uid: id,
      username: map['username'] as String? ?? 'No Name',
      profilePicture:
          map['profile_picture'] as String? ??
          'https://via.placeholder.com/150',
      since: map['since'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profile_picture': profilePicture,
      'since': since,
    };
  }
}
