import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/data/auth_repository.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _editName(BuildContext context, User user) async {
    final ctrl = TextEditingController(text: user.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تعديل الاسم الظاهر'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اسمك'),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'الاسم قصير جدًّا'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogCtx, ctrl.text);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await context.read<AuthRepository>().updateDisplayName(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الاسم بنجاح')),
        );
      }
    } on AuthFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد بالفعل تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.live),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AuthRepository>().signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'مشاهد';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // البطاقة الشخصية
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [Color(0xFF241D3A), Color(0xFF14111D)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                UserAvatar(
                  name: name,
                  photoUrl: user?.photoURL,
                  radius: 30,
                  showLiveRing: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: user == null ? null : () => _editName(context, user),
                  icon: const Icon(Icons.edit_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _SectionTitle('التفضيلات'),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: settings.isDark,
                onChanged: settings.toggleDark,
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('الوضع الليلي'),
                subtitle: const Text('مظهر سينمائي داكن مريح للعين'),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: settings.autoplay,
                onChanged: settings.setAutoplay,
                secondary: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('التشغيل التلقائي'),
                subtitle: const Text('تشغيل الفيديو فور دخول الغرفة'),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: settings.notifications,
                onChanged: settings.setNotifications,
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('الإشعارات'),
                subtitle: const Text('تنبيهات الرسائل ودعوات الغرف'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.high_quality_rounded),
                title: const Text('جودة الفيديو الافتراضية'),
                subtitle: const Text('يمكن تغييرها من المشغّل أيضًا'),
                trailing: DropdownButton<VideoQuality>(
                  value: settings.quality,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(
                      value: VideoQuality.auto,
                      child: Text('تلقائية'),
                    ),
                    DropdownMenuItem(
                      value: VideoQuality.high,
                      child: Text('عالية'),
                    ),
                    DropdownMenuItem(
                      value: VideoQuality.medium,
                      child: Text('متوسطة'),
                    ),
                    DropdownMenuItem(
                      value: VideoQuality.low,
                      child: Text('منخفضة'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.setQuality(v);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _SectionTitle('الحساب'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded),
                title: const Text('تغيير كلمة المرور'),
                subtitle: const Text('إرسال رابط إعادة التعيين بالبريد'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () async {
                  if (email.isEmpty) return;
                  try {
                    await context
                        .read<AuthRepository>()
                        .sendPasswordReset(email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أُرسل رابط إعادة التعيين إلى بريدك'),
                        ),
                      );
                    }
                  } on AuthFailure catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text('الدعم الفني'),
                subtitle: const Text('الإبلاغ عن مشكلة أو اقتراح'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => _infoDialog(
                  context,
                  title: 'الدعم الفني',
                  body:
                      'للتواصل والإبلاغ عن المشكلات:\nsupport@watchtogether.app',
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _SectionTitle('حول التطبيق'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('عن سينما جماعية'),
                trailing: Text(
                  'إصدار ${AppConstants.appVersion}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => _infoDialog(
                  context,
                  title: AppConstants.appName,
                  body:
                      '${AppConstants.appTagline}.\n\n'
                      'شاهد يوتيوب والروابط المباشرة (mp4 و m3u8) داخل غرف '
                      'متزامنة مع دردشة لحظية بين الأصدقاء، مبني بفلاتر وFirebase.',
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('شروط الاستخدام'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => _infoDialog(
                  context,
                  title: 'شروط الاستخدام',
                  body:
                      'استخدم التطبيق لمشاركة المحتوى الذي تملك حق مشاهدته. '
                      'يُمنع نشر محتوى مخالف أو مسيء، ويلتزم المستخدم باحترام '
                      'حقوق الملكية الفكرية لمزوّدي المحتوى.',
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('تقييم التطبيق'),
                subtitle: const Text('شاركنا رأيك في المتجر'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () async {
                  final uri =
                      Uri.parse('https://watchtogether.app/rate');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 28),
          GradientButton(
            label: 'تسجيل الخروج',
            icon: Icons.logout_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.live, Color(0xFFFF7A59)],
            ),
            onPressed: () => _logout(context),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'سينما جماعية • صُنع بشغف ❤️',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _infoDialog(BuildContext context,
      {required String title, required String body}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.8)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
