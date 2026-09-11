import 'dart:convert';
import 'dart:io';

/// يجلب عنوان فيديو يوتيوب عبر خدمة oEmbed الرسمية.
/// يعيد null عند أي فشل أو تجاوز المهلة.
Future<String?> fetchYouTubeTitle(String videoId) async {
  final uri = Uri.parse(
    'https://www.youtube.com/oembed?url='
    '${Uri.encodeComponent('https://www.youtube.com/watch?v=$videoId')}'
    '&format=json',
  );
  final client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 4);
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final title = data['title']?.toString();
    if (title == null || title.trim().isEmpty) return null;
    return title.trim();
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
