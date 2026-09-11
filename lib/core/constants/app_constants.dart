import 'package:flutter/material.dart';

/// ثوابت التطبيق العامة
class AppConstants {
  AppConstants._();

  static const String appName = 'سينما جماعية';
  static const String appTagline = 'شاهدوا معًا في نفس اللحظة';
  static const String appVersion = '1.0.0';

  /// مسارات Realtime Database
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String participantsSub = 'participants';
  static const String messagesSub = 'messages';
}

/// اختصارات المواقع الشهيرة داخل المتصفح الداخلي
class QuickSite {
  const QuickSite({
    required this.name,
    required this.url,
    required this.color,
    required this.icon,
  });

  final String name;
  final String url;
  final Color color;
  final IconData icon;

  static const List<QuickSite> all = [
    QuickSite(
      name: 'يوتيوب',
      url: 'https://m.youtube.com',
      color: Color(0xFFFF0000),
      icon: Icons.smart_display_outlined,
    ),
    QuickSite(
      name: 'جوجل',
      url: 'https://www.google.com',
      color: Color(0xFF4285F4),
      icon: Icons.search_outlined,
    ),
    QuickSite(
      name: 'تيك توك',
      url: 'https://www.tiktok.com',
      color: Color(0xFFFE2C55),
      icon: Icons.music_note_outlined,
    ),
    QuickSite(
      name: 'فيسبوك',
      url: 'https://m.facebook.com',
      color: Color(0xFF1877F2),
      icon: Icons.thumb_up_alt_outlined,
    ),
    QuickSite(
      name: 'إكس',
      url: 'https://x.com',
      color: Color(0xFF9CA3AF),
      icon: Icons.alternate_email,
    ),
    QuickSite(
      name: 'إنستغرام',
      url: 'https://www.instagram.com',
      color: Color(0xFFC13584),
      icon: Icons.camera_alt_outlined,
    ),
    QuickSite(
      name: 'دَيلي موشن',
      url: 'https://www.dailymotion.com',
      color: Color(0xFF0066DC),
      icon: Icons.play_circle_outline,
    ),
    QuickSite(
      name: 'متصفح عام',
      url: 'https://www.google.com',
      color: Color(0xFF7C4DFF),
      icon: Icons.language_outlined,
    ),
  ];
}
