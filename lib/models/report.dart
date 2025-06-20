import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String memoryId;
  final String reportedBy;
  final String reason;
  final Timestamp timestamp;

  Report({
    required this.memoryId,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'memoryId': memoryId,
        'reportedBy': reportedBy,
        'reason': reason,
        'timestamp': timestamp,
      };
}
