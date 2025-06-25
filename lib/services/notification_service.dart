import '../models/notification.dart';
import '../repository/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repository = NotificationRepository();

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _repository.getUserNotifications(userId);
  }

  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
  }) async {
    final notification = AppNotification(
      id: '',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    print('📨 Prepared [$type] notification for $receiverId');
    await _repository.sendNotification(receiverId, notification);
    print('✅ [$type] notification sent to $receiverId');
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) {
    return _repository.markAsRead(userId, notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) {
    return _repository.markAllAsRead(userId);
  }
}
