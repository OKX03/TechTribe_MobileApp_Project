import 'package:firebase_auth/firebase_auth.dart';
import '../repository/friend_repository.dart';
import './notification_service.dart';

class FriendService {
  final FriendRepository _repository = FriendRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<List<Map<String, String>>> fetchFriendRequests() async {
    final me = currentUser;
    if (me == null) return [];
    return _repository.fetchFriendRequests(me.uid);
  }

  Future<List<Map<String, dynamic>>> fetchFriendList() async {
    final me = currentUser;
    if (me == null) return [];
    return _repository.fetchFriendList(me.uid);
  }

  Future<List<Map<String, dynamic>>> fetchRecommendedFriends() async {
    final me = currentUser;
    if (me == null) return [];
    return _repository.fetchRecommendedFriends(me.uid);
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final me = currentUser;
    if (me == null) {
      print('🚫 No logged-in user');
      return;
    }

    print('✅ Sending friend request from ${me.uid} to $toUserId');

    await _repository.sendFriendRequest(me.uid, toUserId);
    print('✅ Friend request record added to Firestore');

    // Send notification
    final senderName = me.displayName ?? 'Someone';
    print('📛 Sender name resolved as: $senderName');

    final _notificationService = NotificationService();
    await _notificationService.sendNotification(
      receiverId: toUserId,
      title: 'New Friend Request',
      body: '$senderName sent you a friend request',
      type: 'friend_request',
    );

    print('📨 Friend request notification sent to $toUserId');
  }

  Future<void> acceptFriendRequest(String fromUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.acceptFriendRequest(fromUid, me.uid);

    // Send notification
    final _notificationService = NotificationService();
    final receiverName = me.displayName ?? 'Someone';
    await _notificationService.sendNotification(
      receiverId: fromUid,
      title: 'Friend Request Accepted',
      body: '$receiverName accepted your friend request',
      type: 'friend_request_accepted',
    );
  }

  Future<void> rejectFriendRequest(String fromUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.rejectFriendRequest(fromUid, me.uid);

    // Send notification
    final _notificationService = NotificationService();
    final rejectorName = me.displayName ?? 'Someone';
    await _notificationService.sendNotification(
      receiverId: fromUid,
      title: 'Friend Request Rejected',
      body: '$rejectorName rejected your friend request',
      type: 'friend_request_rejected',
    );
  }

  Future<void> deleteFriend(String friendUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.deleteFriend(me.uid, friendUid);

    // Send notification
    final _notificationService = NotificationService();
    final removerName = me.displayName ?? 'Someone';
    await _notificationService.sendNotification(
      receiverId: friendUid,
      title: 'Friend Removed',
      body: '$removerName unfriend you',
      type: 'friend_deleted',
    );
  }
}
