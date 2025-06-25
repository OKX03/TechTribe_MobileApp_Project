import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/report.dart';

class ReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReport(Report report) {
    return _db.collection('reports').add(report.toMap());
  }

  // Stream of reports, with optional date filtering
  Stream<QuerySnapshot> getReportsStream({DateTimeRange? filterRange}) {
    Query query = _db.collection('reports');

    if (filterRange != null) {
      query = query
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filterRange.start),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(filterRange.end),
          );
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus newStatus) {
    return _db.collection('reports').doc(reportId).update({
      'status': newStatus.toString().split('.').last,
    });
  }

  // Delete a memory and its associated report
  Future<void> deleteMemoryAndReport({
    required String memoryId,
    required String reportId,
  }) async {
    // Use a batch to ensure both operations succeed or fail together
    final batch = _db.batch();

    // Delete the memory
    final memoryRef = _db.collection('memories').doc(memoryId);
    batch.delete(memoryRef);

    // Delete the report
    final reportRef = _db.collection('reports').doc(reportId);
    batch.delete(reportRef);

    // Delete all comments associated with the memory
    final commentsSnapshot = await memoryRef.collection('comments').get();
    for (var comment in commentsSnapshot.docs) {
      batch.delete(comment.reference);
    }

    // Commit the batch
    await batch.commit();
  }

  // Delete just the report (in case memory was already deleted)
  Future<void> deleteReport(String reportId) {
    return _db.collection('reports').doc(reportId).delete();
  }

  // Fetch a memory document by ID
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    final snapshot = await _db.collection('memories').doc(memoryId).get();
    return snapshot.exists ? snapshot.data() : null;
  }
}
