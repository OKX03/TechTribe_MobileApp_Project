import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_capsule.dart';
import '../repository/capsule_repository.dart';
import './friend_service.dart';
import './notification_service.dart';

class CapsuleService {
  final String userId;
  final CapsuleRepository _repository = CapsuleRepository();

  CapsuleService(this.userId);
  final FriendService _friendService = FriendService();
  final NotificationService _notificationService = NotificationService();

  Future<void> createCapsule(TimeCapsule capsule) async {
    await _repository.addCapsule(capsule, userId);

    // public
    if (capsule.privacy == 'public') {
      final allUsers =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in allUsers.docs) {
        final receiverId = doc.id;
        if (receiverId == userId) continue; // Skip notifying the owner

        await _notificationService.sendNotification(
          receiverId: receiverId,
          title: 'New Public Capsule',
          body: 'A public capsule titled "${capsule.title}" has been created.',
          type: 'capsule_received',
        );
      }
    } else if (capsule.privacy == 'private') { //private
      final friends =
          await _friendService.fetchFriendList(); // returns list of maps
      for (var friend in friends) {
        final friendId = friend['uid'] as String;
        await _notificationService.sendNotification(
          receiverId: friendId,
          title: 'New Capsule Shared (Private)',
          body: 'A capsule titled "${capsule.title}" was shared with you.',
          type: 'capsule_received',
        );
      }
    } else if (capsule.privacy == 'specific') {//specifc
      for (var receiverId in capsule.visibleTo) {
        await _notificationService.sendNotification(
          receiverId: receiverId,
          title: 'New Capsule Shared (Specific)',
          body: 'A capsule titled "${capsule.title}" was shared with you.',
          type: 'capsule_received',
        );
      }
    }
  }

  Future<void> updateCapsule(
    String capsuleId, {
    required String privacy,
    required DateTime unlockDate,
    List<String> visibleTo = const [],
  }) {
    return _repository.updateCapsule(
      capsuleId,
      privacy: privacy,
      unlockDate: unlockDate,
      visibleTo: visibleTo,
    );
  }

  Future<void> deleteCapsule(String capsuleId) {
    return _repository.deleteCapsule(capsuleId);
  }

  Future<List<TimeCapsule>> fetchAllCapsules() {
    return _repository.getCapsules(userId);
  }

  Stream<List<TimeCapsule>> streamLockedCapsules() {
    return _repository.getLockedCapsules(userId);
  }

  Stream<List<TimeCapsule>> streamUnlockedCapsules() {
    return _repository.getAllOrderedByUnlockDate(userId).map((capsules) {
      final now = DateTime.now();
      return capsules
          .where(
            (capsule) =>
                capsule.unlockDate.isBefore(now) ||
                capsule.unlockDate.isAtSameMomentAs(now),
          )
          .toList();
    });
  }

  Future<void> migrateUnlockedCapsules(List<TimeCapsule> capsules) async {
    final now = DateTime.now();
    for (var capsule in capsules) {
      if (capsule.unlockDate.isBefore(now) ||
          capsule.unlockDate.isAtSameMomentAs(now)) {
        await _repository.migrateToMemory(capsule, userId);

        // Notify owner
        await _notificationService.sendNotification(
          receiverId: userId,
          title: 'Capsule Unlocked',
          body: 'Your capsule "${capsule.title}" has been unlocked.',
          type: 'capsule_unlocked',
        );


        // Notify all users (public)
        if (capsule.privacy == 'public') {
          final allUsers =
              await FirebaseFirestore.instance.collection('users').get();

          for (var doc in allUsers.docs) {
            final receiverId = doc.id;
            if (receiverId == userId) continue; // Skip notifying the owner

            await _notificationService.sendNotification(
              receiverId: receiverId,
              title: 'Public Capsule Unlocked',
              body: 'The public capsule "${capsule.title}" is now viewable.',
              type: 'capsule_unlocked_shared',
            );
          }
        } else if (capsule.privacy == 'private') {
          final friends = await _friendService.fetchFriendList(); // Notify accepted friends (private)
          for (var friend in friends) {
            final friendId = friend['uid'] as String;
            await _notificationService.sendNotification(
              receiverId: friendId,
              title: 'Friend\'s Capsule Unlocked',
              body:
                  'A capsule titled "${capsule.title}" from your friend is now viewable.',
              type: 'capsule_unlocked_shared',
            );
          }
        } else if (capsule.privacy == 'specific') { // Notify others if shared (specific privacy)
          for (var viewer in capsule.visibleTo) {
            await _notificationService.sendNotification(
              receiverId: viewer,
              title: 'Shared Capsule Unlocked',
              body:
                  'The capsule "${capsule.title}" shared to you is now viewable.',
              type: 'capsule_unlocked_shared',
            );
          }
        }
      }
    }
  }

  Future<void> migrateToMemory(TimeCapsule capsule) {
    return _repository.migrateToMemory(capsule, userId);
  }
}
