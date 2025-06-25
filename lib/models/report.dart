import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, inReview, resolved, dismissed }

class Report {
  final String memoryId;
  final String reportedBy;
  final String reason;
  final Timestamp timestamp;
  final ReportStatus status;

  Report({
    required this.memoryId,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
    this.status = ReportStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'memoryId': memoryId,
    'reportedBy': reportedBy,
    'reason': reason,
    'timestamp': timestamp,
    'status': status.toString().split('.').last,
  };

  static ReportStatus statusFromString(String status) {
    return ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => ReportStatus.pending,
    );
  }
}
