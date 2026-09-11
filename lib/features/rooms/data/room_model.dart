import 'package:firebase_database/firebase_database.dart';

import '../../../core/utils/video_utils.dart';

/// حالة التشغيل المتزامنة بين جميع الحضور
class PlaybackState {
  const PlaybackState({
    required this.isPlaying,
    required this.positionSeconds,
    required this.updatedAtMs,
    required this.hostUid,
  });

  final bool isPlaying;
  final double positionSeconds;
  final int updatedAtMs;
  final String hostUid;

  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtMs);

  factory PlaybackState.fromMap(Map<dynamic, dynamic> map) => PlaybackState(
        isPlaying: (map['isPlaying'] ?? false) as bool,
        positionSeconds:
            ((map['positionSeconds'] ?? 0) as num).toDouble(),
        updatedAtMs: ((map['updatedAt'] ?? 0) as num).toInt(),
        hostUid: (map['hostUid'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        'updatedAt': updatedAtMs,
        'hostUid': hostUid,
      };
}

class RoomModel {
  const RoomModel({
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.source,
    required this.hostUid,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.createdAtMs,
    this.thumbnailUrl,
    this.youtubeId,
    this.participantCount = 0,
    this.isLive = true,
    this.playback,
  });

  final String id;
  final String name;
  final String videoUrl;
  final VideoSource source;
  final String hostUid;
  final String hostName;
  final String? hostPhotoUrl;
  final String? thumbnailUrl;
  final String? youtubeId;
  final int participantCount;
  final bool isLive;
  final int? createdAtMs;
  final PlaybackState? playback;

  DateTime? get createdAt => createdAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(createdAtMs!);

  factory RoomModel.fromSnapshot(DataSnapshot snapshot) =>
      RoomModel.fromMap(
        Map<dynamic, dynamic>.from((snapshot.value as Map?) ?? const {}),
        snapshot.key ?? '',
      );

  factory RoomModel.fromMap(Map<dynamic, dynamic> data, String id) {
    final sourceName = data['source'] as String?;
    final source = VideoSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => VideoSource.webPage,
    );
    final playbackData = data['playback'] as Map?;
    return RoomModel(
      id: id,
      name: (data['name'] ?? 'غرفة بلا اسم') as String,
      videoUrl: (data['videoUrl'] ?? '') as String,
      source: source,
      hostUid: (data['hostUid'] ?? '') as String,
      hostName: (data['hostName'] ?? 'المضيف') as String,
      hostPhotoUrl: data['hostPhotoUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      youtubeId: data['youtubeId'] as String?,
      participantCount: ((data['participantCount'] ?? 0) as num).toInt(),
      isLive: (data['isLive'] ?? true) as bool,
      createdAtMs: (data['createdAt'] as num?)?.toInt(),
      playback: playbackData == null
          ? null
          : PlaybackState.fromMap(playbackData),
    );
  }
}
