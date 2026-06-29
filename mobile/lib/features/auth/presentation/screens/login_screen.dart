import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/chea_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    // Guard against double-submit from keyboard Enter while a request is
    // already in flight. CheaButton disables its onTap, but onFieldSubmitted
    // calls _submit() directly and bypasses that check.
    if (ref.read(authProvider).isLoading) return;
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted) {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo mark — Material icon avoids Noto font-fallback warnings
                // that emoji glyphs cause on Flutter Web.
                const SizedBox.square(
                  dimension: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: AppRadius.lg,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.science_rounded,
                        color: AppColors.accent,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Welcome back', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text('Sign in to your CHEA account',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 40),

                // Email
                Text('Institute Email', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                      hintText: 'you@students.chea.edu',
                      prefixIcon: Icon(Icons.mail_outline_rounded,
                          color: AppColors.textMuted, size: 20)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                Text('Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Required' : null,
                ),
                const SizedBox(height: 32),

                CheaButton(
                  label: 'Sign In',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Register'),
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
