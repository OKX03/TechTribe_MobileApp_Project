import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReport(Report report) {
    return _db.collection('reports').add(report.toMap());
  }
}