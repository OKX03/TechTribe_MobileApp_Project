import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool showUnread = true;
  final NotificationService _notificationService = NotificationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              //mark all as read
              if (_currentUser != null) {
                _notificationService.markAllNotificationsAsRead(_currentUser!.uid);
                setState(() {
                  showUnread = false; // Refresh to show all notifications
                });
              }
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Toggle Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [showUnread, !showUnread],
                  onPressed: (index) {
                    setState(() {
                      showUnread = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(30),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue.shade700,
                  color: Colors.grey,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 75),
                      child: Text('Unread'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 75),
                      child: Text('All'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.getUserNotifications(
                _currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load notifications'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allNotifications = snapshot.data!;
                final notifications =
                    showUnread
                        ? allNotifications.where((n) => !n.isRead).toList()
                        : allNotifications;

                if (notifications.isEmpty) {
                  return const Center(child: Text('No notifications.'));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationTile(
                      id: notif.id,
                      title: notif.title,
                      message: notif.body,
                      time: DateFormat('hh:mm a').format(notif.timestamp),
                      type: notif.type,
                      isUnread: !notif.isRead,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String id,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required String type,
  }) {
    IconData icon = Icons.notifications;
    Color iconColor = isUnread ? Colors.green : Colors.grey;

    // Customize icon for different types
    switch (type) {
      case 'friend_request':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case 'friend_request_accepted':
        icon = Icons.person_add_alt_1;
        iconColor = Colors.green;
        break;
      case 'friend_request_rejected':
        icon = Icons.person_remove;
        iconColor = Colors.orange;
        break;
      case 'friend_deleted':
        icon = Icons.block;
        iconColor = Colors.redAccent;
        break;
      case 'capsule_created':
        icon = Icons.add_box;
        iconColor = Colors.deepPurple;
        break;
      case 'capsule_received':
        icon = Icons.move_to_inbox;
        iconColor = Colors.teal;
        break;
      case 'capsule_unlocked':
        icon = Icons.lock_open;
        iconColor = Colors.indigo;
        break;
      case 'capsule_unlocked_shared':
        icon = Icons.lock_open_outlined;
        iconColor = Colors.lightBlue;
        break;
      case 'memory_deleted':
        icon = Icons.delete_forever;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Icon(
            isUnread ? Icons.mark_email_unread : Icons.check_circle,
            color: isUnread ? Colors.grey : Colors.blue,
            size: 18,
          ),
        ],
      ),
      onTap: () async {
        if (isUnread && _currentUser != null) {
          await _notificationService.markNotificationAsRead(
            _currentUser!.uid,
            id,
          );
        }
      },
    );
  }
}
