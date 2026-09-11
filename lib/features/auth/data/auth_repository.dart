import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
    FirebaseDatabase? database,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = database ?? FirebaseDatabase.instance;

  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  DatabaseReference get _users => _db.ref(AppConstants.usersCollection);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> get currentUserProfile async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _users.child(user.uid).get();
    if (snapshot.exists) return AppUser.fromSnapshot(snapshot);
    return AppUser.fromFirebase(user);
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
    } catch (_) {
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
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _users.child(credential.user!.uid).set(appUser.toMap()
        ..['createdAt'] = ServerValue.timestamp);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e.code));
    } catch (_) {
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
      await _users.child(user.uid).update({'name': name.trim()});
      await user.reload();
    } catch (_) {
      throw AuthFailure('تعذّر تحديث البيانات.');
    }
  }

  Future<void> signOut() => _auth.signOut();

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
