/// نتيجة التقاط فيديو من المتصفح الداخلي:
/// الرابط مع عنوان الفيديو/الصفحة التي التُقط منها.
class MediaCapture {
  const MediaCapture({required this.url, this.title});

  final String url;
  final String? title;

  String? get cleanTitle {
    final t = title?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// يزيل اللواحق الشائعة التي تضيفها المواقع لعنوان الصفحة
  static String? normalizeTitle(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;
    const suffixes = [
      ' - YouTube',
      ' | YouTube',
      ' - Facebook',
      ' | Facebook',
      ' • TikTok',
      ' - TikTok',
    ];
    for (final s in suffixes) {
      if (t.endsWith(s)) t = t.substring(0, t.length - s.length).trim();
    }
    return t.isEmpty ? null : t;
  }

  @override
  String toString() => 'MediaCapture(url: $url, title: $title)';
}
