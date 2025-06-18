import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';

class FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch pending friend requests
  Future<List<Map<String, String>>> fetchFriendRequests(String userId) async {
    final qs =
        await _firestore
            .collection('friendList')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

    final ownerIds = qs.docs.map((d) => d['ownerId'] as String).toList();
    if (ownerIds.isEmpty) return [];

    final users =
        await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: ownerIds)
            .get();

    return users.docs.map((u) {
      final d = u.data();
      return {
        'uid': u.id,
        'username': d['username'] as String? ?? 'No Name',
        'profile_picture':
            d['profile_picture'] as String? ??
            'https://via.placeholder.com/150',
      };
    }).toList();
  }

  // Fetch accepted friends
  Future<List<Map<String, dynamic>>> fetchFriendList(String userId) async {
    final asOwner =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final asFriend =
        await _firestore
            .collection('friendList')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final friendData = <String, Timestamp>{};
    for (var d in asOwner.docs) {
      friendData[d['friendId'] as String] = d['since'] as Timestamp;
    }
    for (var d in asFriend.docs) {
      friendData[d['ownerId'] as String] = d['since'] as Timestamp;
    }

    if (friendData.isEmpty) return [];

    final users =
        await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: friendData.keys.toList())
            .get();

    return users.docs.map((u) {
      final d = u.data();
      return {
        'uid': u.id,
        'username': d['username'] as String? ?? 'No Name',
        'profile_picture':
            d['profile_picture'] as String? ??
            'https://via.placeholder.com/150',
        'since': friendData[u.id],
      };
    }).toList();
  }

  // Fetch recommended friends
  Future<List<Map<String, dynamic>>> fetchRecommendedFriends(
    String userId,
  ) async {
    final myFriendsSnap1 =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();
    final myFriendsSnap2 =
        await _firestore
            .collection('friendList')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final myFriendIds = <String>{};
    for (var d in myFriendsSnap1.docs) {
      myFriendIds.add(d['friendId'] as String);
    }
    for (var d in myFriendsSnap2.docs) {
      myFriendIds.add(d['ownerId'] as String);
    }

    final excluded = <String>{userId, ...myFriendIds};
    final allUsersSnap = await _firestore.collection('users').get();

    final myPendingSnap =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();
    final myPendingIds =
        myPendingSnap.docs.map((d) => d['friendId'] as String).toSet();

    List<Map<String, dynamic>> candidates = [];
    for (var userDoc in allUsersSnap.docs) {
      final userId = userDoc.id;
      if (excluded.contains(userId)) continue;

      final theirFriendsSnap1 =
          await _firestore
              .collection('friendList')
              .where('ownerId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();
      final theirFriendsSnap2 =
          await _firestore
              .collection('friendList')
              .where('friendId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();

      final theirFriendIds = <String>{};
      for (var d in theirFriendsSnap1.docs) {
        theirFriendIds.add(d['friendId'] as String);
      }
      for (var d in theirFriendsSnap2.docs) {
        theirFriendIds.add(d['ownerId'] as String);
      }

      final mutualFriends = myFriendIds.intersection(theirFriendIds).length;

      final d = userDoc.data();
      candidates.add({
        'uid': userId,
        'username': d['username'] as String? ?? 'No Name',
        'profile_picture':
            d['profile_picture'] as String? ??
            'https://via.placeholder.com/150',
        'mutualFriends': mutualFriends,
        'createdAt': d['createdAt'],
        'isPending': myPendingIds.contains(userId),
      });
    }

    candidates.sort((a, b) => b['mutualFriends'].compareTo(a['mutualFriends']));
    return candidates;
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _firestore.collection('friendList').add({
      'ownerId': fromUserId,
      'friendId': toUserId,
      'status': 'pending',
      'since': FieldValue.serverTimestamp(),
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String fromUid, String toUid) async {
    final q =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: fromUid)
            .where('friendId', isEqualTo: toUid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
    if (q.docs.isEmpty) return;
    final doc = q.docs.first.reference;

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.update(doc, {'status': 'accepted', 'since': now});
    batch.set(_firestore.collection('friendList').doc(), {
      'ownerId': toUid,
      'friendId': fromUid,
      'status': 'accepted',
      'since': now,
    });

    await batch.commit();
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String fromUid, String toUid) async {
    final q =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: fromUid)
            .where('friendId', isEqualTo: toUid)
            .where('status', isEqualTo: 'pending')
            .get();
    for (var d in q.docs) {
      await d.reference.delete();
    }
  }

  // Delete friend (unfriend)
  Future<void> deleteFriend(String userId1, String userId2) async {
    final batch = _firestore.batch();

    final mine =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: userId1)
            .where('friendId', isEqualTo: userId2)
            .where('status', isEqualTo: 'accepted')
            .get();
    mine.docs.forEach((d) => batch.delete(d.reference));

    final theirs =
        await _firestore
            .collection('friendList')
            .where('ownerId', isEqualTo: userId2)
            .where('friendId', isEqualTo: userId1)
            .where('status', isEqualTo: 'accepted')
            .get();
    theirs.docs.forEach((d) => batch.delete(d.reference));

    await batch.commit();
  }
}
