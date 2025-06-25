import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/memory_repository.dart';

class MemoryService {
  final MemoryRepository _repo = MemoryRepository();

  Future<DocumentSnapshot> getMemory(String memoryId) {
    return _repo.getMemory(memoryId);
  }

  Stream<QuerySnapshot> getMyMemories(String userId) {
    return _repo.getMemories(userId);
  }

  Stream<QuerySnapshot> getSharedMemories(String userId) {
    return _repo.getSharedMemories(userId);
  }

  Future<void> toggleLike({
    required String memoryId,
    required String userId,
    required bool isLiked,
    required List<String> likedBy,
  }) async {
    if (isLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await _repo.updateLikes(memoryId, likedBy);
  }

  Future<void> reportMemory(String memoryId, String userId) {
    return _repo.addReport(memoryId: memoryId, reportedBy: userId);
  }

  Future<void> submitComment(String memoryId, String userId, String text) {
    return _repo.addComment(memoryId: memoryId, userId: userId, text: text);
  }

  Stream<QuerySnapshot> getComments(String memoryId) {
    return _repo.getCommentsStream(memoryId);
  }

  Future<DocumentSnapshot> getUserProfile(String userId) {
    return _repo.getUserById(userId);
  }

  Future<void> deleteMemory(String memoryId) {
    return _repo.deleteMemory(memoryId);
  }

  // New methods for branch functionality
  Future<void> createBranch({
    required String parentMemoryId,
    required String title,
    required String description,
    required String ownerId,
    required List<String> photoUrls,
    required List<String> videoUrls,
    required List<String> audioUrls,
    required List<String> fileUrls,
    required String privacy,
    required DateTime unlockDate,
  }) async {
    final parentMemory = await getMemory(parentMemoryId);
    final parentData = parentMemory.data() as Map<String, dynamic>;
    final parentBranchLevel = parentData['branchLevel'] ?? 0;

    final memoryData = {
      'title': title,
      'description': description,
      'unlockedAt': Timestamp.now(),
      'unlockDate': Timestamp.fromDate(unlockDate),
      'privacy': privacy,
      'createdAt': Timestamp.now(),
      'ownerId': ownerId,
      'visibleTo': [],
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'audioUrls': audioUrls,
      'fileUrls': fileUrls,
      'likedBy': [],
      'isBranch': true,
      'branchLevel': parentBranchLevel + 1,
      'parentMemoryId': parentMemoryId,
    };

    await _repo.memories.add(memoryData);
  }

  Stream<QuerySnapshot> getBranchMemories(String parentMemoryId) {
    return _repo.memories
        .where('parentMemoryId', isEqualTo: parentMemoryId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteBranch(String memoryId) async {
    // First, get all child branches
    final branches =
        await _repo.memories.where('parentMemoryId', isEqualTo: memoryId).get();

    // Delete all child branches recursively
    for (var branch in branches.docs) {
      await deleteBranch(branch.id);
    }

    // Finally, delete the current branch
    await deleteMemory(memoryId);
  }
}
