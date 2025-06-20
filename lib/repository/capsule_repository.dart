// import '../models/time_capsule.dart';
// import '../services/capsule_service.dart';

// class CapsuleRepository {
//   final CapsuleService _firestoreService;

//   CapsuleRepository(this._firestoreService);

//   Future<void> createCapsule(TimeCapsule capsule) {
//     return _firestoreService.addCapsule(capsule);
//   }

//   Future<void> updateCapsule(
//     String capsuleId, {
//     required String privacy,
//     required DateTime unlockDate,
//     List<String> visibleTo = const [],
//   }) {
//     return _firestoreService.updateCapsule(
//       capsuleId,
//       privacy: privacy,
//       unlockDate: unlockDate,
//       visibleTo: visibleTo,
//     );
//   }


//   Future<void> deleteCapsule(String capsuleId) {
//     return _firestoreService.deleteCapsule(capsuleId);
//   }

//   Future<List<TimeCapsule>> fetchAllCapsules() {
//     return _firestoreService.getCapsules();
//   }

//   Stream<List<TimeCapsule>> streamLockedCapsules() {
//     return _firestoreService.streamLockedCapsules();
//   }

//   Stream<List<TimeCapsule>> streamUnlockedCapsules() {
//     return _firestoreService.streamUnlockedCapsules();
//   }

//   Future<void> migrateUnlockedCapsules(List<TimeCapsule> capsules) async {
//     final now = DateTime.now();
//     for (var capsule in capsules) {
//       if (capsule.unlockDate.isBefore(now)) {
//         await _firestoreService.migrateToMemory(capsule);
//       }
//     }
//   }

// }
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_capsule.dart';

class CapsuleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCapsule(TimeCapsule capsule,String userId) async {
    await _db.collection('capsules').add({
      ...capsule.toJson(),
      'ownerId': userId,
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

  Future<List<TimeCapsule>> getCapsules(String userId) async {
    final query = await _db
        .collection('capsules')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => TimeCapsule.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<TimeCapsule>> getCapsulesStream(String userId) {
    return _db
        .collection('capsules')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TimeCapsule.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<TimeCapsule>> getLockedCapsules(String userId) {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('capsules')
        .where('ownerId', isEqualTo: userId)
        .where('unlockDate', isGreaterThan: now)
        .orderBy('unlockDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TimeCapsule.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<TimeCapsule>> getAllOrderedByUnlockDate(String userId) {
    return _db
        .collection('capsules')
        .where('ownerId', isEqualTo: userId)
        .orderBy('unlockDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TimeCapsule.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> migrateToMemory(TimeCapsule capsule,String userId) async {
    final now = DateTime.now();
    final memoryData = capsule.toJson();
    memoryData['unlockedAt'] = Timestamp.fromDate(now);
    memoryData['createdAt'] = capsule.createdAt ?? Timestamp.fromDate(now);
    memoryData['ownerId'] = userId;

    final batch = _db.batch();
    final memoryRef = _db.collection('memories').doc(capsule.id);
    final capsuleRef = _db.collection('capsules').doc(capsule.id);
    batch.set(memoryRef, memoryData);
    batch.delete(capsuleRef);

    await batch.commit();
  }
}
