// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/time_capsule.dart';

// class CapsuleService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final String _userId;

//   CapsuleService(this._userId);

//   Future<void> addCapsule(TimeCapsule capsule) async {
//     await _db.collection('capsules').add({
//       ...capsule.toJson(),
//       'ownerId': _userId,
//       'createdAt': Timestamp.fromDate(DateTime.now()),
//     });
//   }

//   Future<void> updateCapsule(
//     String capsuleId, {
//     required String privacy,
//     required DateTime unlockDate,
//     List<String> visibleTo = const [],
//   }) async {
//     await _db.collection('capsules').doc(capsuleId).update({
//       'privacy': privacy,
//       'unlockDate': Timestamp.fromDate(unlockDate),
//       'visibleTo': visibleTo,
//     });
//   }

//   Future<void> deleteCapsule(String capsuleId) async {
//     await _db.collection('capsules').doc(capsuleId).delete();
//   }

//   Future<List<TimeCapsule>> getCapsules() async {
//     final query = await _db
//         .collection('capsules')
//         .where('ownerId', isEqualTo: _userId)
//         .orderBy('createdAt', descending: true)
//         .get();

//     return query.docs
//         .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
//         .toList();
//   }

//   Stream<List<TimeCapsule>> getCapsulesStream() {
//     final userCapsulesRef = _db
//         .collection('capsules')
//         .where('ownerId', isEqualTo: _userId)
//         .orderBy('createdAt', descending: true);
//     return userCapsulesRef.snapshots().map((snapshot) =>
//         snapshot.docs.map((doc) {
//           return TimeCapsule.fromJson(doc.data(), doc.id);
//         }).toList());
//   }

// Future<void> migrateToMemory(TimeCapsule capsule) async {
//   final now = DateTime.now();

//   // Debug print statements to help diagnose the issue
//   print('Current time: $now');
//   print('Capsule unlock date: ${capsule.unlockDate}');

//   // Check if capsule can be unlocked based on current time
//   if (capsule.unlockDate.isAfter(now)) {
//     print("Capsule not ready to unlock: ${capsule.title}");
//     print("Time remaining: ${capsule.unlockDate.difference(now)}");
//     return;
//   }

//   try {
//     // Create memory document first
//     final memoryData = capsule.toJson();
//     memoryData['unlockedAt'] = Timestamp.fromDate(now);
//     memoryData['createdAt'] = capsule.createdAt ?? Timestamp.fromDate(now);
//     memoryData['ownerId'] = _userId;

//     // Use a batch to ensure atomicity
//     final batch = _db.batch();

//     // Add memory document
//     final memoryRef = _db.collection('memories').doc(capsule.id);
//     batch.set(memoryRef, memoryData);

//     // Delete capsule document
//     final capsuleRef = _db.collection('capsules').doc(capsule.id);
//     batch.delete(capsuleRef);

//     // Commit the batch
//     await batch.commit();

//     print("Successfully migrated capsule to memory: ${capsule.title}");
//   } catch (e) {
//     print('Error migrating capsule to memory: $e');
//     throw e;
//   }
// }

// Stream<List<TimeCapsule>> streamLockedCapsules() {
//   final now = Timestamp.fromDate(DateTime.now());
//   return _db
//       .collection('capsules')
//       .where('ownerId', isEqualTo: _userId)
//       .where('unlockDate', isGreaterThan: now)
//       .orderBy('unlockDate')
//       .snapshots()
//       .map((snapshot) => snapshot.docs
//           .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
//           .toList());
// }

// Stream<List<TimeCapsule>> streamUnlockedCapsules() {
//   return _db
//       .collection('capsules')
//       .where('ownerId', isEqualTo: _userId)
//       .orderBy('unlockDate')
//       .snapshots()
//       .map((snapshot) {
//         final now = DateTime.now();
//         final unlockedCapsules = <TimeCapsule>[];

//         for (final doc in snapshot.docs) {
//           final capsule = TimeCapsule.fromJson(doc.data(), doc.id);
//           if (capsule.unlockDate.isBefore(now) || capsule.unlockDate.isAtSameMomentAs(now)) {
//             migrateToMemory(capsule);
//             unlockedCapsules.add(capsule);
//           }
//         }

//         return unlockedCapsules;
//       });
// }

// }
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
