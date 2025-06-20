import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../repository/report_repository.dart';

class ReportService {
  final ReportRepository _repository = ReportRepository();

  Future<void> reportMemory({
    required String memoryId,
    required String userId,
    required String reason,
  }) async {
    final report = Report(
      memoryId: memoryId,
      reportedBy: userId,
      reason: reason,
      timestamp: Timestamp.now(),
    );

    await _repository.addReport(report);

    // Remove reported user from visibleTo
    await FirebaseFirestore.instance
        .collection('memories')
        .doc(memoryId)
        .update({
      'visibleTo': FieldValue.arrayRemove([userId]),
    });
  }
}
