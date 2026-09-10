import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import 'app_user.dart';

/// أخطاء مترجمة للعربية للمستخدم
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> get currentUserProfile async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return AppUser.fromDoc(doc);
    return AppUser(
      uid: user.uid,
      name: user.displayName ?? 'مشاهد',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e.code));
    } catch (e) {
      throw AuthFailure('تعذّر تسجيل الدخول. تحقق من اتصالك بالإنترنت.');
    }
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());

      final appUser = AppUser(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );
      await _users.doc(credential.user!.uid).set(appUser.toMap());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e.code));
    } catch (e) {
      throw AuthFailure('تعذّر إنشاء الحساب. حاول مرة أخرى.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e.code));
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthFailure('المستخدم غير مسجل');
    try {
      await user.updateDisplayName(name.trim());
      await _users.doc(user.uid).set(
        {'name': name.trim()},
        SetOptions(merge: true),
      );
      await user.reload();
    } catch (e) {
      throw AuthFailure('تعذّر تحديث البيانات.');
    }
  }

  Future<void> signOut() => _auth.signOut();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  String _mapError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'بريد إلكتروني أو كلمة مرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًّا (6 أحرف على الأقل)';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، انتظر قليلًا ثم أعد المحاولة';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد غير مفعّل في إعدادات Firebase';
      default:
        return 'حدث خطأ، حاول مرة أخرى';
    }
  }
}
