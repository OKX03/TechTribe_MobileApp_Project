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

  Stream<List<TimeCapsule>> streamLockedCapsules() {
    print("Fetching locked capsules for: $_userId");
    return _db
        .collection('capsules')
        .where('ownerId', isEqualTo: _userId)
        .where('unlockDate', isGreaterThan: Timestamp.now()) // 🔒 only locked
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
      .where('unlockDate', isLessThanOrEqualTo: Timestamp.now())
      .orderBy('unlockDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
          .toList());
}

Future<void> migrateToMemory(TimeCapsule capsule) async {
  final now = DateTime.now();
  if (capsule.unlockDate.isAfter(now)) {
    // Safety: do not migrate locked capsules
    print("Skipping locked capsule: ${capsule.title}");
    return;
  }

  final memoryData = capsule.toJson();
  memoryData['unlockedAt'] = Timestamp.fromDate(now);
  memoryData['ownerId'] = _userId;

  await _db.collection('memories').doc(capsule.id).set(memoryData);
  await _db.collection('capsules').doc(capsule.id).delete(); // only delete if safe
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