import 'package:firebase_database/firebase_database.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.text,
    required this.uid,
    required this.senderName,
    this.senderPhotoUrl,
    this.createdAtMs,
  });

  final String id;
  final String text;
  final String uid;
  final String senderName;
  final String? senderPhotoUrl;
  final int? createdAtMs;

  DateTime? get createdAt => createdAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(createdAtMs!);

  factory MessageModel.fromSnapshot(DataSnapshot snapshot) =>
      MessageModel.fromMap(
        Map<dynamic, dynamic>.from((snapshot.value as Map?) ?? const {}),
        snapshot.key ?? '',
      );

  factory MessageModel.fromMap(Map<dynamic, dynamic> data, String id) =>
      MessageModel(
        id: id,
        text: (data['text'] ?? '') as String,
        uid: (data['uid'] ?? '') as String,
        senderName: (data['senderName'] ?? 'مشاهد') as String,
        senderPhotoUrl: data['senderPhotoUrl'] as String?,
        createdAtMs: (data['createdAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'uid': uid,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'createdAt': ServerValue.timestamp,
      };
}
