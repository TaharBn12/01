import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/realtime_clock.dart';
import '../../../core/utils/video_utils.dart';
import '../../auth/data/app_user.dart';
import 'message_model.dart';
import 'room_model.dart';

class RoomsFailure implements Exception {
  RoomsFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class _Presence {
  _Presence(this.memberRef, this.countRef);
  final DatabaseReference memberRef;
  final DatabaseReference countRef;
}

class RoomsRepository {
  RoomsRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance {
    RealtimeClock.start(_db);
  }

  final FirebaseDatabase _db;
  final Map<String, _Presence> _presence = {};

  DatabaseReference get _rooms => _db.ref(AppConstants.roomsCollection);
  DatabaseReference _room(String id) => _rooms.child(id);

  // --------------------------------------------------------------- الغرف

  Stream<List<RoomModel>> watchRooms({bool liveOnly = false}) {
    return _rooms
        .orderByChild('createdAt')
        .limitToLast(100)
        .onValue
        .map((event) {
      final value = event.snapshot.value as Map?;
      if (value == null) return <RoomModel>[];
      final rooms = value.entries
          .map((entry) => RoomModel.fromMap(
                Map<dynamic, dynamic>.from(entry.value as Map),
                entry.key,
              ))
          .toList();
      rooms.sort((a, b) =>
          (b.createdAtMs ?? 0).compareTo(a.createdAtMs ?? 0));
      return liveOnly ? rooms.where((r) => r.isLive).toList() : rooms;
    });
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _room(roomId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) {
        throw RoomsFailure('الغرفة غير موجودة');
      }
      return RoomModel.fromSnapshot(snapshot);
    });
  }

  Future<RoomModel?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final snapshot = await _room(normalized).get();
    if (!snapshot.exists) return null;
    return RoomModel.fromSnapshot(snapshot);
  }

  Future<RoomModel> createRoom({
    required String name,
    required String rawVideoUrl,
    required AppUser host,
  }) async {
    final video = VideoUtils.inspect(rawVideoUrl);
    final now = DateTime.now().millisecondsSinceEpoch;

    String? code;
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = VideoUtils.generateRoomCode();
      final existing = await _room(candidate).get();
      if (!existing.exists) {
        code = candidate;
        break;
      }
    }
    if (code == null) {
      throw RoomsFailure('تعذّر إنشاء الغرفة، حاول مرة أخرى.');
    }

    final room = RoomModel(
      id: code,
      name: name.trim(),
      videoUrl: video.url,
      source: video.source,
      youtubeId: video.youtubeId,
      thumbnailUrl: video.thumbnailUrl,
      hostUid: host.uid,
      hostName: host.name,
      hostPhotoUrl: host.photoUrl,
      participantCount: 1,
      isLive: true,
      createdAtMs: now,
      playback: PlaybackState(
        isPlaying: true,
        positionSeconds: 0,
        updatedAtMs: now,
        hostUid: host.uid,
      ),
    );

    await _room(code).set({
      'name': room.name,
      'videoUrl': room.videoUrl,
      'source': room.source.name,
      'youtubeId': room.youtubeId,
      'thumbnailUrl': room.thumbnailUrl,
      'hostUid': room.hostUid,
      'hostName': room.hostName,
      'hostPhotoUrl': room.hostPhotoUrl,
      'participantCount': 1,
      'isLive': true,
      'createdAt': ServerValue.timestamp,
      'playback': room.playback!.toMap()..['updatedAt'] = now,
    });

    await _room(code)
        .child(AppConstants.participantsSub)
        .child(host.uid)
        .set({
      ...host.toPresenceMap(),
      'joinedAt': ServerValue.timestamp,
    });

    await _registerPresence(code, host.uid);
    return room;
  }

  Future<void> changeVideo(String roomId, String rawVideoUrl) async {
    final video = VideoUtils.inspect(rawVideoUrl);
    await _room(roomId).update({
      'videoUrl': video.url,
      'source': video.source.name,
      'youtubeId': video.youtubeId,
      'thumbnailUrl': video.thumbnailUrl,
      'playback': PlaybackState(
        isPlaying: true,
        positionSeconds: 0,
        updatedAtMs: RealtimeClock.nowMs,
        hostUid: '',
      ).toMap()
        ..['updatedAt'] = ServerValue.timestamp,
    });
  }

  Future<void> closeRoom(String roomId) =>
      _room(roomId).update({'isLive': false});

  // ----------------------------------------------------------- الحضور

  Stream<List<AppUser>> watchParticipants(String roomId) {
    return _room(roomId)
        .child(AppConstants.participantsSub)
        .onValue
        .map((event) {
      final value = event.snapshot.value as Map?;
      if (value == null) return <AppUser>[];
      return value.entries
          .map((entry) => AppUser.fromMap(
                Map<dynamic, dynamic>.from(entry.value as Map),
                entry.key,
              ))
          .toList();
    });
  }

  /// يسجّل إزالة الحضور تلقائيًّا عند انقطاع الاتصال
  Future<void> _registerPresence(String roomId, String uid) async {
    final memberRef =
        _room(roomId).child(AppConstants.participantsSub).child(uid);
    final countRef = _room(roomId).child('participantCount');

    await memberRef.onDisconnect().remove();
    await countRef.onDisconnect().set(ServerValue.increment(-1));
    _presence['$roomId/$uid'] = _Presence(memberRef, countRef);
  }

  Future<void> joinRoom(String roomId, AppUser user) async {
    final memberRef =
        _room(roomId).child(AppConstants.participantsSub).child(user.uid);
    final existing = await memberRef.get();
    if (existing.exists) {
      await _registerPresence(roomId, user.uid);
      return;
    }

    await _registerPresence(roomId, user.uid);
    await memberRef.set({
      ...user.toPresenceMap(),
      'joinedAt': ServerValue.timestamp,
    });
    await _room(roomId)
        .child('participantCount')
        .runTransaction((value) {
      final current = (value as int?) ?? 0;
      return Transaction.success(current + 1);
    });
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    final key = '$roomId/$uid';
    final presence = _presence.remove(key);
    final memberRef = presence?.memberRef ??
        _room(roomId).child(AppConstants.participantsSub).child(uid);
    final countRef =
        presence?.countRef ?? _room(roomId).child('participantCount');

    try {
      await memberRef.onDisconnect().cancel();
      await countRef.onDisconnect().cancel();
    } catch (_) {}

    final existing = await memberRef.get();
    if (existing.exists) {
      await memberRef.remove();
      await countRef.runTransaction((value) {
        final current = (value as int?) ?? 0;
        return Transaction.success(current > 0 ? current - 1 : 0);
      });
    }
  }

  // ----------------------------------------------------------- الرسائل

  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _room(roomId)
        .child(AppConstants.messagesSub)
        .orderByChild('createdAt')
        .limitToLast(100)
        .onValue
        .map((event) {
      final value = event.snapshot.value as Map?;
      if (value == null) return <MessageModel>[];
      final messages = value.entries
          .map((entry) => MessageModel.fromMap(
                Map<dynamic, dynamic>.from(entry.value as Map),
                entry.key,
              ))
          .toList();
      // الأحدث أولاً (قائمة العرض معكوسة)
      return messages.reversed.toList();
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required AppUser user,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final message = MessageModel(
      id: '',
      text: trimmed,
      uid: user.uid,
      senderName: user.name,
      senderPhotoUrl: user.photoUrl,
    );
    await _room(roomId)
        .child(AppConstants.messagesSub)
        .push()
        .set(message.toMap());
  }

  // ----------------------------------------------------------- المزامنة

  Future<void> updatePlayback({
    required String roomId,
    required String hostUid,
    required bool isPlaying,
    required double positionSeconds,
  }) {
    return _room(roomId).update({
      'playback': PlaybackState(
        isPlaying: isPlaying,
        positionSeconds: positionSeconds,
        updatedAtMs: RealtimeClock.nowMs,
        hostUid: hostUid,
      ).toMap()
        ..['updatedAt'] = ServerValue.timestamp,
    });
  }
}
