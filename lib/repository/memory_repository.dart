import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get memories => _firestore.collection('memories');
  CollectionReference get reports => _firestore.collection('reports');

  Future<DocumentSnapshot> getMemory(String memoryId) {
    return memories.doc(memoryId).get();
  }

  // Get own memories
  Stream<QuerySnapshot> getMemories(String userId) {
    return memories
        .where('ownerId', isEqualTo: userId)
        .orderBy('unlockedAt', descending: true)
        .snapshots();
  }

  // Get shared memories (if using array of UIDs in 'visibleTo')
  Stream<QuerySnapshot> getSharedMemories(String userId) {
    return memories
        .where('visibleTo', arrayContains: userId)
        .orderBy('unlockedAt', descending: true)
        .snapshots();
  }

  Future<void> updateLikes(String memoryId, List<String> likedBy) {
    return memories.doc(memoryId).update({'likedBy': likedBy});
  }

  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<void> addReport({required String memoryId, required String reportedBy}) {
    return reports.add({
      'memoryId': memoryId,
      'reportedBy': reportedBy,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> addComment({
    required String memoryId,
    required String userId,
    required String text,
  }) {
    return memories
        .doc(memoryId)
        .collection('comments')
        .add({'text': text, 'userId': userId, 'createdAt': Timestamp.now()});
  }

  Stream<QuerySnapshot> getCommentsStream(String memoryId) {
    return memories
        .doc(memoryId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteMemory(String memoryId) async {
    await memories.doc(memoryId).delete();
  }
}
