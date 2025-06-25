import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the user's notifications
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  // Marks a single notification as read.
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Sends  notification 
  Future<void> sendNotification(
    String userId,
    AppNotification notification,
  ) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .add(notification.toMap());
  }

  // Marks all notifications as read 
  Future<void> markAllAsRead(String userId) async {
    final notifRef = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications');

    final unread = await notifRef.where('isRead', isEqualTo: false).get();

    for (var doc in unread.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}
