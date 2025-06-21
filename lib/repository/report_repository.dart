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
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(filterRange.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(filterRange.end));
    }
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Fetch a memory document by ID
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    final snapshot = await _db.collection('memories').doc(memoryId).get();
    return snapshot.exists ? snapshot.data() : null;
  }
}