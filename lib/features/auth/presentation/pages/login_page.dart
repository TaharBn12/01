import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().signIn(
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.go('/');
    } on AuthFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('تعذّر تسجيل الدخول، تحقق من إعداد Firebase أولًا.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _email.text);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'البريد الإلكتروني'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, emailCtrl.text),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await context.read<AuthRepository>().sendPasswordReset(result);
      _snack('أُرسل رابط الاستعادة إلى بريدك ✉️');
    } on AuthFailure catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 90),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/app_logo.png'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppConstants.appTagline,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
              ),
              const SizedBox(height: 42),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _email,
                      label: 'البريد الإلكتروني',
                      hint: 'name@example.com',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _password,
                      label: 'كلمة المرور',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      validator: Validators.password,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _forgotPassword,
                        icon: const Icon(Icons.lock_reset_rounded, size: 17),
                        label: const Text('نسيت كلمة المرور؟'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GradientButton(
                      label: 'تسجيل الدخول',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onPressed: _login,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'أنشئ حسابًا جديدًا',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FirebaseWarning(),
            ],
          ),
        ),
      ),
    );
  }
}

/// تنبيه صغير يظهر فقط قبل استبدال مفاتيح Firebase المؤقتة
class _FirebaseWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configured =
        FirebaseAuth.instance.app.options.apiKey != 'YOUR_ANDROID_API_KEY' &&
            FirebaseAuth.instance.app.options.apiKey != 'YOUR_IOS_API_KEY' &&
            !FirebaseAuth.instance.app.options.apiKey.startsWith('YOUR_');
    if (configured) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'استبدل مفاتيح Firebase المؤقتة في lib/firebase_options.dart '
              'باتباع خطوات README قبل تسجيل الدخول.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
