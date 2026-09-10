import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.text,
    required this.uid,
    required this.senderName,
    this.senderPhotoUrl,
    this.createdAt,
  });

  final String id;
  final String text;
  final String uid;
  final String senderName;
  final String? senderPhotoUrl;
  final DateTime? createdAt;

  factory MessageModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MessageModel(
      id: doc.id,
      text: (data['text'] ?? '') as String,
      uid: (data['uid'] ?? '') as String,
      senderName: (data['senderName'] ?? 'مشاهد') as String,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'uid': uid,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
