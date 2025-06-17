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
}
