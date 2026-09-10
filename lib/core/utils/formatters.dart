import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// "منذ ٥ دقائق" — نص عربي ودود للزمن
  static String timeAgo(DateTime? time) {
    if (time == null) return 'الآن';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'الآن';
    if (diff.inMinutes < 1) return 'منذ ثوانٍ';
    if (diff.inMinutes == 1) return 'منذ دقيقة';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours == 1) return 'منذ ساعة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return DateFormat('yyyy/MM/dd', 'ar').format(time);
  }

  static String timeOfDay(DateTime time) =>
      DateFormat('hh:mm a', 'ar').format(time);

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '؟';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first;
    }
    return parts.first.characters.first + parts[1].characters.first;
  }

  static String counter(int count) {
    if (count == 1) return 'مشاهد واحد';
    if (count == 2) return 'مشاهدان';
    if (count <= 10) return '$count مشاهدين';
    return '$count مشاهد';
  }
}
