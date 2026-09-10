import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/video_utils.dart';

/// حالة التشغيل المتزامنة بين جميع الحضور
class PlaybackState {
  const PlaybackState({
    required this.isPlaying,
    required this.positionSeconds,
    required this.updatedAt,
    required this.hostUid,
  });

  final bool isPlaying;
  final double positionSeconds;
  final DateTime updatedAt;
  final String hostUid;

  factory PlaybackState.fromMap(Map<String, dynamic> map) => PlaybackState(
        isPlaying: (map['isPlaying'] ?? false) as bool,
        positionSeconds:
            (map['positionSeconds'] ?? 0).toDouble(),
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        hostUid: (map['hostUid'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        'updatedAt': Timestamp.fromDate(updatedAt),
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
    required this.createdAt,
    this.thumbnailUrl,
    this.youtubeId,
    this.participantCount = 0,
    this.isLive = true,
    this.playback,
  });

  /// معرّف الغرفة وهو نفسه كود الدعوة القصير
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
  final DateTime? createdAt;
  final PlaybackState? playback;

  factory RoomModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final sourceName = data['source'] as String?;
    final source = VideoSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => VideoSource.webPage,
    );
    return RoomModel(
      id: doc.id,
      name: (data['name'] ?? 'غرفة بلا اسم') as String,
      videoUrl: (data['videoUrl'] ?? '') as String,
      source: source,
      hostUid: (data['hostUid'] ?? '') as String,
      hostName: (data['hostName'] ?? 'المضيف') as String,
      hostPhotoUrl: data['hostPhotoUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      youtubeId: data['youtubeId'] as String?,
      participantCount: (data['participantCount'] ?? 0) as int,
      isLive: (data['isLive'] ?? true) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      playback: data['playback'] is Map<String, dynamic>
          ? PlaybackState.fromMap(data['playback'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'videoUrl': videoUrl,
        'source': source.name,
        'hostUid': hostUid,
        'hostName': hostName,
        'hostPhotoUrl': hostPhotoUrl,
        'thumbnailUrl': thumbnailUrl,
        'youtubeId': youtubeId,
        'participantCount': participantCount,
        'isLive': isLive,
        'createdAt':
            createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };
}
