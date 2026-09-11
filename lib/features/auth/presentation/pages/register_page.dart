import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _agreed = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _snack('يجب الموافقة على شروط الاستخدام');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.go('/');
    } on AuthFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('تعذّر إنشاء الحساب، تحقق من اتصالك وإعداد Firebase.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'انضم إلى ${AppConstants.appName} 🎬',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أنشئ حسابك المجاني وابدأ غرفة المشاهدة خلال ثوانٍ.',
                  style: TextStyle(color: context.text3, height: 1.7),
                ),
                const SizedBox(height: 26),
                AppTextField(
                  controller: _name,
                  label: 'الاسم الظاهر',
                  hint: 'مثال: أحمد محمد',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                ),
                const SizedBox(height: 18),
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
                  hint: '6 أحرف على الأقل',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _confirm,
                  label: 'تأكيد كلمة المرور',
                  hint: 'أعد كتابة كلمة المرور',
                  prefixIcon: Icons.verified_user_outlined,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: context.mono,
                  title: const Text(
                    'أوافق على شروط الاستخدام وسياسة الخصوصية',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'إنشاء الحساب',
                  icon: Icons.person_add_alt_1_rounded,
                  loading: _loading,
                  onPressed: _register,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟',
                      style: TextStyle(color: context.text3),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: context.mono,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
