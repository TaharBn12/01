import 'package:flutter_test/flutter_test.dart';
import 'package:watch_together/core/utils/video_utils.dart';

void main() {
  group('VideoUtils', () {
    test('يتعرّف على روابط يوتيوب بصيغها المختلفة', () {
      const watch = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      const short = 'https://youtu.be/dQw4w9WgXcQ';
      const shorts = 'https://youtube.com/shorts/dQw4w9WgXcQ';
      const embed = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
      const mobile = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';

      for (final url in [watch, short, shorts, embed, mobile]) {
        expect(VideoUtils.extractYouTubeId(url), 'dQw4w9WgXcQ',
            reason: 'failed for $url');
        expect(VideoUtils.inspect(url).source, VideoSource.youtube);
      }
    });

    test('يتعرّف على الروابط المباشرة', () {
      expect(
        VideoUtils.inspect('https://example.com/movie.mp4').source,
        VideoSource.directVideo,
      );
      expect(
        VideoUtils.inspect('https://stream.example.com/live/index.m3u8').source,
        VideoSource.directVideo,
      );
      expect(
        VideoUtils.inspect('https://example.com/v.webm?token=abc').source,
        VideoSource.directVideo,
      );
    });

    test('يعتبر الروابط الأخرى صفحات ويب', () {
      expect(
        VideoUtils.inspect('https://example.com/watch/page').source,
        VideoSource.webPage,
      );
    });

    test('يضيف بروتوكول https تلقائيًّا', () {
      expect(
        VideoUrlNormalizer.normalize('example.com/m.mp4'),
        'https://example.com/m.mp4',
      );
    });

    test('يولّد كود غرفة من 6 خانات بأحرف واضحة', () {
      final code = VideoUtils.generateRoomCode();
      expect(code.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);
      expect(code.contains('I'), isFalse);
      expect(code.contains('O'), isFalse);
    });

    test('صورة يوتيوب المصغّرة تُبنى من المعرّف', () {
      expect(
        VideoUtils.youtubeThumbnail('abc12345678'),
        'https://img.youtube.com/vi/abc12345678/hqdefault.jpg',
      );
    });
  });
}
