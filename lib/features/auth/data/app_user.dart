import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (data['name'] ?? 'مشاهد') as String,
      email: (data['email'] ?? '') as String,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) => AppUser(
        uid: uid,
        name: (data['name'] ?? 'مشاهد') as String,
        email: (data['email'] ?? '') as String,
        photoUrl: data['photoUrl'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt':
            createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory AppUser.fromFirebase(User user) => AppUser(
        uid: user.uid,
        name: (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'مشاهد'),
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );

  AppUser copyWith({String? name, String? photoUrl}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );
}
