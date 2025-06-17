import '../models/time_capsule.dart';
import '../services/capsule_firestore_service.dart';

class CapsuleRepository {
  final CapsuleFirestoreService _firestoreService;

  CapsuleRepository(this._firestoreService);

  Future<void> createCapsule(TimeCapsule capsule) {
    return _firestoreService.addCapsule(capsule);
  }

  Future<void> updateCapsule(
    String capsuleId, {
    required String privacy,
    required DateTime unlockDate,
    List<String> visibleTo = const [],
  }) {
    return _firestoreService.updateCapsule(
      capsuleId,
      privacy: privacy,
      unlockDate: unlockDate,
      visibleTo: visibleTo,
    );
  }


  Future<void> deleteCapsule(String capsuleId) {
    return _firestoreService.deleteCapsule(capsuleId);
  }

  Future<List<TimeCapsule>> fetchAllCapsules() {
    return _firestoreService.getCapsules();
  }

  Stream<List<TimeCapsule>> streamLockedCapsules() {
    return _firestoreService.streamLockedCapsules();
  }

  Stream<List<TimeCapsule>> streamUnlockedCapsules() {
    return _firestoreService.streamUnlockedCapsules();
  }

  Future<void> migrateUnlockedCapsules(List<TimeCapsule> capsules) async {
    final now = DateTime.now();
    for (var capsule in capsules) {
      if (capsule.unlockDate.isBefore(now)) {
        await _firestoreService.migrateToMemory(capsule);
      }
    }
  }







  

  // Future<List<String>> changePrivacy(){
  //   return _firestoreService.handlePrivacy(privacy: privacy);
  // }
}
