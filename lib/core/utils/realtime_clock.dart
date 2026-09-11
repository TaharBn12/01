import 'package:firebase_database/firebase_database.dart';

/// ساعة متزامنة مع زمن خادم Realtime Database
/// لاحتساب فرق الموضع بين المضيف والضيوف بدقة.
class RealtimeClock {
  RealtimeClock._();

  static int _offsetMs = 0;
  static bool _started = false;

  static int get offsetMs => _offsetMs;
  static int get nowMs =>
      DateTime.now().millisecondsSinceEpoch + _offsetMs;

  static void start(FirebaseDatabase db) {
    if (_started) return;
    _started = true;
    db.ref('.info/serverTimeOffset').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is num) _offsetMs = value.round();
    });
  }
}
