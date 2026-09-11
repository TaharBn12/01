import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.createdAtMs,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final int? createdAtMs;

  DateTime? get createdAt => createdAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(createdAtMs!);

  factory AppUser.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(
      (snapshot.value as Map?) ?? const {},
    );
    return AppUser.fromMap(data, snapshot.key ?? '');
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> data, String uid) => AppUser(
        uid: uid,
        name: (data['name'] ?? 'مشاهد') as String,
        email: (data['email'] ?? '') as String,
        photoUrl: data['photoUrl'] as String?,
        createdAtMs: (data['createdAt'] as num?)?.toInt(),
      );

  factory AppUser.fromFirebase(User user) => AppUser(
        uid: user.uid,
        name: (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'مشاهد'),
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );

  /// بيانات العضو داخل قائمة الحضور
  Map<String, dynamic> toPresenceMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
      };

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAtMs,
      };

  AppUser copyWith({String? name, String? photoUrl}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAtMs: createdAtMs,
      );
}
