import 'package:firebase_auth/firebase_auth.dart';
import '../repository/friend_repository.dart';

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
    if (me == null) return;
    await _repository.sendFriendRequest(me.uid, toUserId);
  }

  Future<void> acceptFriendRequest(String fromUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.acceptFriendRequest(fromUid, me.uid);
  }

  Future<void> rejectFriendRequest(String fromUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.rejectFriendRequest(fromUid, me.uid);
  }

  Future<void> deleteFriend(String friendUid) async {
    final me = currentUser;
    if (me == null) return;
    await _repository.deleteFriend(me.uid, friendUid);
  }
}
