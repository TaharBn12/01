/// أنواع مصادر الفيديو المدعومة
enum VideoSource {
  youtube,
  directVideo,
  webPage,
  unknown;

  String get label {
    switch (this) {
      case VideoSource.youtube:
        return 'يوتيوب';
      case VideoSource.directVideo:
        return 'رابط مباشر';
      case VideoSource.webPage:
        return 'صفحة ويب';
      case VideoSource.unknown:
        return 'غير معروف';
    }
  }

  bool get playable =>
      this == VideoSource.youtube || this == VideoSource.directVideo;
}

class VideoInfo {
  const VideoInfo({
    required this.url,
    required this.source,
    this.youtubeId,
    this.thumbnailUrl,
  });

  final String url;
  final VideoSource source;
  final String? youtubeId;
  final String? thumbnailUrl;
}

class VideoUtils {
  VideoUtils._();

  static final RegExp _youtubeReg = RegExp(
    r'^(https?:\/\/)?((www\.|m\.|music\.)?)youtube\.com\/(watch\?v=|embed\/|v\/|live\/|shorts\/)([\w\-]{11})',
    caseSensitive: false,
  );
  static final RegExp _youtuBeReg = RegExp(
    r'^(https?:\/\/)?youtu\.be\/([\w\-]{11})',
    caseSensitive: false,
  );
  static final RegExp _directExt = RegExp(
    r'\.(mp4|m3u8|webm|ogg|ogv|mov|mkv|m4v|ts|mpd)([?#].*)?$',
    caseSensitive: false,
  );

  /// يستخرج معرّف فيديو يوتيوب من أي صيغة رابط معروفة
  static String? extractYouTubeId(String input) {
    final url = input.trim();
    final match = _youtubeReg.firstMatch(url) ?? _youtuBeReg.firstMatch(url);
    if (match != null) {
      return match.group(match.groupCount);
    }
    // صيغة query العامة: ?v=ID
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host;
      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.length >= 11) return v.substring(0, 11);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (host.contains('youtu.be') && segments.isNotEmpty) {
          return segments.first.length >= 11
              ? segments.first.substring(0, 11)
              : segments.first;
        }
      }
    }
    return null;
  }

  static bool isYouTube(String url) => extractYouTubeId(url) != null;

  static bool isDirectVideo(String url) => _directExt.hasMatch(url);

  static VideoInfo inspect(String rawUrl) {
    final url = VideoUrlNormalizer.normalize(rawUrl);
    final ytId = extractYouTubeId(url);
    if (ytId != null) {
      return VideoInfo(
        url: url,
        source: VideoSource.youtube,
        youtubeId: ytId,
        thumbnailUrl: youtubeThumbnail(ytId),
      );
    }
    if (isDirectVideo(url)) {
      return VideoInfo(url: url, source: VideoSource.directVideo);
    }
    if (url.isNotEmpty) {
      return VideoInfo(url: url, source: VideoSource.webPage);
    }
    return VideoInfo(url: url, source: VideoSource.unknown);
  }

  static String? youtubeThumbnail(String videoId) =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// كود غرفة قصير وسهل القراءة (6 خانات بدون رموز ملتبسة)
  static String generateRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    var seed = now;
    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(alphabet[seed % alphabet.length]);
    }
    return buffer.toString();
  }
}

/// يطبّع الروابط بحيث تحمل بروتوكول https افتراضيًّا
class VideoUrlNormalizer {
  VideoUrlNormalizer._();

  static String normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }
}
