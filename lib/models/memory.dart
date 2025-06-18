import 'package:cloud_firestore/cloud_firestore.dart';

class Memory {
  final String id;
  final String title;
  final String description;
  final DateTime unlockedAt;
  final DateTime unlockDate;
  final String privacy;
  final DateTime createdAt;
  final String ownerId;
  final List<String> visibleTo;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final List<String> audioUrls;
  final List<String> fileUrls;
  final List<String> likedBy;
  final bool isBranch;
  final int branchLevel;
  final String? parentMemoryId;

  Memory({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedAt,
    required this.unlockDate,
    required this.privacy,
    required this.createdAt,
    required this.ownerId,
    this.visibleTo = const [],
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.audioUrls = const [],
    this.fileUrls = const [],
    this.likedBy = const [],
    this.isBranch = false,
    this.branchLevel = 0,
    this.parentMemoryId,
  });

  factory Memory.fromJson(Map<String, dynamic> json, String docId) {
    return Memory(
      id: docId,
      title: json['title'],
      description: json['description'],
      unlockedAt: (json['unlockedAt'] as Timestamp).toDate(),
      unlockDate: (json['unlockDate'] as Timestamp).toDate(),
      privacy: json['privacy'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      ownerId: json['ownerId'],
      visibleTo: List<String>.from(json['visibleTo'] ?? []),
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      audioUrls: List<String>.from(json['audioUrls'] ?? []),
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isBranch: json['isBranch'] ?? false,
      branchLevel: json['branchLevel'] ?? 0,
      parentMemoryId: json['parentMemoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'unlockDate': Timestamp.fromDate(unlockDate),
      'privacy': privacy,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'visibleTo': visibleTo,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'audioUrls': audioUrls,
      'fileUrls': fileUrls,
      'likedBy': likedBy,
      'isBranch': isBranch,
      'branchLevel': branchLevel,
      'parentMemoryId': parentMemoryId,
    };
  }
}
