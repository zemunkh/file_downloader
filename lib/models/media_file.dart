import 'package:cloud_firestore/cloud_firestore.dart';

class MyMediaFile {
  final String id;
  final String fileType;
  final int fileSize;
  final bool isReminder;
  final bool isDeleted;
  final String label;
  final String name;
  final String userId;
  final String fileUrl;
  final Timestamp createdOn;

  MyMediaFile(
      {required this.id,
      required this.fileType,
      required this.fileSize,
      required this.isReminder,
      required this.isDeleted,
      required this.label,
      required this.name,
      required this.userId,
      required this.fileUrl,
      required this.createdOn});

  MyMediaFile.fromJson(Map<String, Object?> data)
      : this(
          id: data['id'] as String,
          fileType: data['fileType'] as String,
          fileSize: data['fileSize'] as int,
          isReminder: data['isReminder'] as bool,
          isDeleted: data['isDeleted'] as bool,
          label: data['label'] as String,
          name: data['name'] as String,
          userId: data['userId'] as String,
          fileUrl: data['fileUrl'] as String,
          // audioUrl: data['audioUrl'] as String,
          createdOn: data['createdOn'] as Timestamp,
        );

  Map<String, Object> toJson() {
    return {
      'id': id,
      'fileType': fileType,
      'isReminder': isReminder,
      'isDeleted': isDeleted,
      'label': label,
      'name': name,
      'userId': userId,
      'fileUrl': fileUrl,
      'createdOn': createdOn,
    };
  }
}
