import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// الزر الرئيسي في التطبيق — صلب بلون التمييز (أبيض/أسود) بدون تدرجات.
/// يبقى اسم GradientButton توافقيًّا مع الاستدعاءات الحالية.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  /// تدرج مخصّص اختياري (يتجاوز النمط الأحادي إن مُرّر)
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final custom = gradient != null && !disabled;
    final bg = custom ? null : (disabled ? context.variant : context.mono);
    final fg = custom
        ? Colors.white
        : disabled
            ? context.text3
            : context.onMono;

    return Opacity(
      opacity: disabled && !loading ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onPressed,
          child: Ink(
            width: expand ? double.infinity : null,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              gradient: custom ? gradient : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fg, size: 19),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شعار التطبيق: مربع صلب بلون التمييز مع مثلّث تشغيل معكوس اللون
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.radius = 16});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.mono,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: context.onMono,
        size: size * 0.62,
      ),
    );
  }
}
