import 'video_utils.dart';

class Validators {
  Validators._();

  static String? required(String? value, {String field = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field مطلوب';
    }
    return null;
  }

  static String? name(String? value) {
    final req = required(value, field: 'الاسم');
    if (req != null) return req;
    if (value!.trim().length < 3) {
      return 'الاسم قصير جدًّا (3 أحرف على الأقل)';
    }
    if (value.trim().length > 30) {
      return 'الاسم طويل جدًّا';
    }
    return null;
  }

  static String? email(String? value) {
    final req = required(value, field: 'البريد الإلكتروني');
    if (req != null) return req;
    final pattern = RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'بريد إلكتروني غير صالح';
    }
    return null;
  }

  static String? password(String? value) {
    final req = required(value, field: 'كلمة المرور');
    if (req != null) return req;
    if (value!.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final req = required(value, field: 'تأكيد كلمة المرور');
    if (req != null) return req;
    if (value != original) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  static String? roomName(String? value) {
    final req = required(value, field: 'اسم الغرفة');
    if (req != null) return req;
    if (value!.trim().length < 3) {
      return 'اسم الغرفة قصير جدًّا';
    }
    return null;
  }

  static String? videoUrl(String? value) {
    final req = required(value, field: 'رابط المشاهدة');
    if (req != null) return req;
    final uri = Uri.tryParse(VideoUrlNormalizer.normalize(value!.trim()));
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'رابط غير صالح';
    }
    return null;
  }
}
