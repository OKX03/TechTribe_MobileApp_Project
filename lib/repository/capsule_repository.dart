import '../models/time_capsule.dart';
import '../services/capsule_firestore_service.dart';

class CapsuleRepository {
  final CapsuleFirestoreService _firestoreService;

  CapsuleRepository(this._firestoreService);

  Future<void> createCapsule(TimeCapsule capsule) {
    return _firestoreService.addCapsule(capsule);
  }

  Future<void> updateCapsule(String capsuleId, {
    required String privacy,
    required DateTime unlockDate,
  }) {
    return _firestoreService.updateCapsule(capsuleId, privacy: privacy, unlockDate: unlockDate);
  }

  Future<void> deleteCapsule(String capsuleId) {
    return _firestoreService.deleteCapsule(capsuleId);
  }

  Future<List<TimeCapsule>> fetchAllCapsules() {
    return _firestoreService.getCapsules();
  }

  Stream<List<TimeCapsule>> streamCapsules() {
    return _firestoreService.getCapsulesStream();
  }
}
