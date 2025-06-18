import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_capsule.dart';

class CapsuleFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId;

  CapsuleFirestoreService(this._userId);

  Future<void> addCapsule(TimeCapsule capsule) async {
    await _db.collection('capsules').add({
      ...capsule.toJson(),
      'ownerId': _userId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateCapsule(
    String capsuleId, {
    required String privacy,
    required DateTime unlockDate,
    List<String> visibleTo = const [],
  }) async {
    await _db.collection('capsules').doc(capsuleId).update({
      'privacy': privacy,
      'unlockDate': Timestamp.fromDate(unlockDate),
      'visibleTo': visibleTo,
    });
  }


  Future<void> deleteCapsule(String capsuleId) async {
    await _db.collection('capsules').doc(capsuleId).delete();
  }

  Future<List<TimeCapsule>> getCapsules() async {
    final query = await _db
        .collection('capsules')
        .where('ownerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<TimeCapsule>> getCapsulesStream() {
    final userCapsulesRef = _db
        .collection('capsules')
        .where('ownerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true);
    return userCapsulesRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          return TimeCapsule.fromJson(doc.data(), doc.id);
        }).toList());
  }

Future<void> migrateToMemory(TimeCapsule capsule) async {
  final now = DateTime.now();
  
  // Debug print statements to help diagnose the issue
  print('Current time: $now');
  print('Capsule unlock date: ${capsule.unlockDate}');

  // Check if capsule can be unlocked based on current time
  if (capsule.unlockDate.isAfter(now)) {
    print("Capsule not ready to unlock: ${capsule.title}");
    print("Time remaining: ${capsule.unlockDate.difference(now)}");
    return;
  }

  try {
    // Create memory document first
    final memoryData = capsule.toJson();
    memoryData['unlockedAt'] = Timestamp.fromDate(now);
    memoryData['createdAt'] = capsule.createdAt ?? Timestamp.fromDate(now);
    memoryData['ownerId'] = _userId;

    // Use a batch to ensure atomicity
    final batch = _db.batch();
    
    // Add memory document
    final memoryRef = _db.collection('memories').doc(capsule.id);
    batch.set(memoryRef, memoryData);
    
    // Delete capsule document
    final capsuleRef = _db.collection('capsules').doc(capsule.id);
    batch.delete(capsuleRef);

    // Commit the batch
    await batch.commit();
    
    print("Successfully migrated capsule to memory: ${capsule.title}");
  } catch (e) {
    print('Error migrating capsule to memory: $e');
    throw e;
  }
}

Stream<List<TimeCapsule>> streamLockedCapsules() {
  final now = Timestamp.fromDate(DateTime.now());
  return _db
      .collection('capsules')
      .where('ownerId', isEqualTo: _userId)
      .where('unlockDate', isGreaterThan: now)
      .orderBy('unlockDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
          .toList());
}

Stream<List<TimeCapsule>> streamUnlockedCapsules() {
  return _db
      .collection('capsules')
      .where('ownerId', isEqualTo: _userId)
      .orderBy('unlockDate')
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();
        final unlockedCapsules = <TimeCapsule>[];

        for (final doc in snapshot.docs) {
          final capsule = TimeCapsule.fromJson(doc.data(), doc.id);
          if (capsule.unlockDate.isBefore(now) || capsule.unlockDate.isAtSameMomentAs(now)) {
            migrateToMemory(capsule);
            unlockedCapsules.add(capsule);
          }
        }

        return unlockedCapsules;
      });
}







  

  // Future<List<String>> handlePrivacy({
  //     required String privacy,
  //     List<String> selectedFriendIds = const [],
  //   }) async {
    

  //     if (privacy == 'Private') return [];

  //     if (privacy == 'Public') {
  //       final firestore = FirebaseFirestore.instance;

  //       final asOwner = await firestore
  //           .collection('friendList')
  //           .where('ownerId', isEqualTo: _userId)
  //           .where('status', isEqualTo: 'accepted')
  //           .get();

  //       final asFriend = await firestore
  //           .collection('friendList')
  //           .where('friendId', isEqualTo: _userId)
  //           .where('status', isEqualTo: 'accepted')
  //           .get();

  //       final friendUids = <String>{};

  //       for (var doc in asOwner.docs) {
  //         friendUids.add(doc['friendId']);
  //       }
  //       for (var doc in asFriend.docs) {
  //         friendUids.add(doc['ownerId']);
  //       }

  //       return friendUids.toList();
  //     }

  //     if (privacy == 'Specific') {
  //       return selectedFriendIds;
  //     }

  //     return [_userId]; // Fallback to private
  //   }

}