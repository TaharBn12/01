import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
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

class RoomsRepository {
  RoomsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection(AppConstants.roomsCollection);

  DocumentReference<Map<String, dynamic>> _roomDoc(String id) =>
      _rooms.doc(id);

  // --------------------------------------------------------------- الغرف

  Stream<List<RoomModel>> watchRooms({bool liveOnly = false}) {
    Query<Map<String, dynamic>> query = _rooms;
    if (liveOnly) {
      query = query.where('isLive', isEqualTo: true);
    }
    query = query.orderBy('createdAt', descending: true).limit(100);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map(RoomModel.fromDoc).toList(growable: false));
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _roomDoc(roomId).snapshots().map((doc) {
      if (!doc.exists) {
        throw RoomsFailure('الغرفة غير موجودة');
      }
      return RoomModel.fromDoc(doc);
    });
  }

  Future<RoomModel?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final doc = await _roomDoc(normalized).get();
    if (!doc.exists) return null;
    return RoomModel.fromDoc(doc);
  }

  Future<RoomModel> createRoom({
    required String name,
    required String rawVideoUrl,
    required AppUser host,
  }) async {
    final video = VideoUtils.inspect(rawVideoUrl);
    String code;
    // توليد كود فريد غير متكرر
    for (var attempt = 0; attempt < 8; attempt++) {
      code = VideoUtils.generateRoomCode();
      final existing = await _roomDoc(code).get();
      if (!existing.exists) {
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
          createdAt: DateTime.now(),
          playback: PlaybackState(
            isPlaying: true,
            positionSeconds: 0,
            updatedAt: DateTime.now(),
            hostUid: host.uid,
          ),
        );
        final data = room.toMap();
        data['playback'] = room.playback!.toMap();
        await _roomDoc(code).set(data);
        await _joinWithoutCount(code, host);
        return room;
      }
    }
    throw RoomsFailure('تعذّر إنشاء الغرفة، حاول مرة أخرى.');
  }

  Future<void> changeVideo(String roomId, String rawVideoUrl) async {
    final video = VideoUtils.inspect(rawVideoUrl);
    await _roomDoc(roomId).update({
      'videoUrl': video.url,
      'source': video.source.name,
      'youtubeId': video.youtubeId,
      'thumbnailUrl': video.thumbnailUrl,
      'playback': PlaybackState(
        isPlaying: true,
        positionSeconds: 0,
        updatedAt: DateTime.now(),
        hostUid: '',
      ).toMap(),
    });
  }

  Future<void> closeRoom(String roomId) =>
      _roomDoc(roomId).update({'isLive': false});

  // ----------------------------------------------------------- الحضور

  Stream<List<AppUser>> watchParticipants(String roomId) {
    return _roomDoc(roomId)
        .collection(AppConstants.participantsSub)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data(), doc.id))
            .toList(growable: false));
  }

  Future<void> joinRoom(String roomId, AppUser user) async {
    final ref = _roomDoc(roomId)
        .collection(AppConstants.participantsSub)
        .doc(user.uid);
    final existing = await ref.get();
    if (!existing.exists) {
      await _db.runTransaction((transaction) async {
        final roomSnap = await transaction.get(_roomDoc(roomId));
        if (!roomSnap.exists) {
          throw RoomsFailure('الغرفة غير موجودة');
        }
        transaction.set(ref, {
          'name': user.name,
          'email': user.email,
          'photoUrl': user.photoUrl,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(_roomDoc(roomId), {
          'participantCount': FieldValue.increment(1),
        });
      });
    }
  }

  Future<void> _joinWithoutCount(String roomId, AppUser user) async {
    await _roomDoc(roomId)
        .collection(AppConstants.participantsSub)
        .doc(user.uid)
        .set({
      'name': user.name,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    final ref =
        _roomDoc(roomId).collection(AppConstants.participantsSub).doc(uid);
    final existing = await ref.get();
    if (existing.exists) {
      await _db.runTransaction((transaction) async {
        final roomSnap = await transaction.get(_roomDoc(roomId));
        if (!roomSnap.exists) return;
        final current =
            (roomSnap.data()?['participantCount'] ?? 1) as int;
        transaction.delete(ref);
        transaction.update(_roomDoc(roomId), {
          'participantCount': FieldValue.increment(current > 0 ? -1 : 0),
        });
      });
    }
  }

  // ----------------------------------------------------------- الرسائل

  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _roomDoc(roomId)
        .collection(AppConstants.messagesSub)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(MessageModel.fromDoc)
            .toList(growable: false));
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
    await _roomDoc(roomId)
        .collection(AppConstants.messagesSub)
        .add(message.toMap());
  }

  // ----------------------------------------------------------- المزامنة

  /// يحدّث موضع التشغيل (يستدعيه المضيف فقط)
  Future<void> updatePlayback({
    required String roomId,
    required String hostUid,
    required bool isPlaying,
    required double positionSeconds,
  }) {
    return _roomDoc(roomId).update({
      'playback': PlaybackState(
        isPlaying: isPlaying,
        positionSeconds: positionSeconds,
        updatedAt: DateTime.now(),
        hostUid: hostUid,
      ).toMap(),
    });
  }
}
