import '../../../../core/utils/realtime_clock.dart';
import '../../data/room_model.dart';

/// يُستدعى محليًّا عند تغيّر التشغيل (تشغيل/إيقاف/تقديم) ليرفعه المضيف
typedef LocalPlaybackCallback = void Function(
  bool isPlaying,
  double positionSeconds,
);

/// منطق مشترك لمزامنة التشغيل بين الحضور
mixin PlaybackSyncMixin {
  String? _lastRemoteKey;

  /// يطبّق حالة التشغيل القادمة من المضيف على الضيوف
  /// ويعيد الموضع المقدَّر بعد احتساب زمن الشبكة وفق ساعة الخادم
  double? resolveRemotePosition(
    PlaybackState state, {
    required bool isHost,
    required String myUid,
  }) {
    if (isHost) return null; // المضيف هو المصدر
    if (state.hostUid == myUid) return null;
    final key = '${state.updatedAtMs}-${state.positionSeconds}';
    if (key == _lastRemoteKey) return null;
    _lastRemoteKey = key;
    var target = state.positionSeconds;
    if (state.isPlaying) {
      final elapsed =
          (RealtimeClock.nowMs - state.updatedAtMs) / 1000.0;
      target += elapsed.clamp(0, 30);
    }
    return target;
  }
}
