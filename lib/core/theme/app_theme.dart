import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام تصميم أحادي اللون (أبيض / أسود / رمادي)
/// أسلوب تحريري أنظف: حواف أقل استدارة، حدود شعريّة، تباين حاد.
class AppColors {
  AppColors._();

  // ===== الوضع الداكن =====
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF121214);
  static const Color surfaceVariant = Color(0xFF1B1B1F);
  static const Color card = Color(0xFF131316);
  static const Color border = Color(0xFF29292E);
  static const Color hairline = Color(0x1FFFFFFF); // أبيض 12%

  // لون التمييز في الوضع الداكن = أبيض نقي
  static const Color primary = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFFD8D8DD);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color live = Color(0xFFFFFFFF);
  static const Color success = Color(0xFFC8C8CF);
  static const Color warning = Color(0xFF9B9BA3);
  static const Color youtube = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA7A7B0);
  static const Color textMuted = Color(0xFF6E6E78);

  // ===== الوضع الفاتح =====
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightVariant = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightText = Color(0xFF0A0A0B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFF8E8E96);
}

/// ألوان حسّاسة للثيم (تُقرأ من سياق الويدجت)
extension MonoTheme on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;

  /// اللون الأساسي للثيم: أبيض في الداكن، أسود في الفاتح
  Color get mono => _dark ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0B);

  /// عكس اللون الأساسي (لون النص فوقه)
  Color get onMono => _dark ? const Color(0xFF0A0A0B) : const Color(0xFFFFFFFF);

  Color get bg =>
      _dark ? AppColors.background : AppColors.lightBackground;
  Color get cardColor => _dark ? AppColors.card : AppColors.lightCard;
  Color get variant =>
      _dark ? AppColors.surfaceVariant : AppColors.lightVariant;
  Color get line => _dark ? AppColors.border : AppColors.lightBorder;
  Color get text1 =>
      _dark ? AppColors.textPrimary : AppColors.lightText;
  Color get text2 =>
      _dark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get text3 =>
      _dark ? AppColors.textMuted : AppColors.lightTextMuted;
}

/// تدرجات رمادية باهتة جدًّا (للخلفيات فقط)
class AppGradients {
  AppGradients._();

  /// تدرج محايد (لا ألوان)
  static const LinearGradient neutral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F1F23), Color(0xFF101012)],
  );

  static const LinearGradient roomCard = neutral;

  /// يبقى الاسم القديم متاحًا كمرادف محايد
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFECECEF)],
  );

  static LinearGradient hero(BuildContext context) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          context.mono.withValues(alpha: 0.06),
          context.bg.withValues(alpha: 0),
        ],
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF0A0A0B),
      secondary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF0A0A0B),
      surface: Color(0xFF121214),
      onSurface: Color(0xFFFAFAFA),
      error: Color(0xFFFFFFFF),
      onError: Color(0xFF0A0A0B),
      outline: Color(0xFF29292E),
    );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      primaryColor: Colors.white,
      textTheme: _textTheme(base.textTheme, AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surfaceVariant,
        border: AppColors.border,
        focused: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _solidButton(
          bg: Colors.white,
          fg: Colors.black,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _solidButton(bg: Colors.white, fg: Colors.black),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
          color: Colors.black,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: GoogleFonts.cairo(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: Colors.white,
        showCheckmark: false,
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.cairo(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.cairo(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.surfaceVariant,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll(AppColors.border),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13.5),
        dividerColor: AppColors.border,
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: Color(0xFF0A0A0B),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF0A0A0B),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0A0A0B),
      error: Color(0xFF0A0A0B),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFE4E4E7),
    );

    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      primaryColor: Colors.black,
      textTheme: _textTheme(base.textTheme, AppColors.lightText),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.lightVariant,
        border: AppColors.lightBorder,
        focused: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _solidButton(bg: Colors.black, fg: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _solidButton(bg: Colors.black, fg: Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText,
          side: const BorderSide(color: AppColors.lightBorder),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: Colors.black,
        showCheckmark: false,
        side: const BorderSide(color: AppColors.lightBorder),
        labelStyle: GoogleFonts.cairo(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.lightTextMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : AppColors.lightVariant,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll(AppColors.lightBorder),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: Colors.black,
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.lightTextMuted,
        labelStyle:
            GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13.5),
        dividerColor: AppColors.lightBorder,
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focused,
  }) {
    OutlineInputBorder borderFor(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.cairo(color: AppColors.textMuted),
      labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: borderFor(border),
      enabledBorder: borderFor(border),
      focusedBorder: borderFor(focused, 1.6),
      errorBorder: borderFor(focused, 1.2),
    );
  }

  static ButtonStyle _solidButton({
    required Color bg,
    required Color fg,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      minimumSize: const Size.fromHeight(52),
      textStyle: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color color) {
    return GoogleFonts.cairoTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
  }
}
