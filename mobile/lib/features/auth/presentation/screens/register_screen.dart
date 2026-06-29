import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/chea_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form       = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _rollCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  int _semester     = 1;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _rollCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
      email:      _emailCtrl.text.trim(),
      password:   _passCtrl.text,
      fullName:   _nameCtrl.text.trim(),
      rollNumber: _rollCtrl.text.trim().isEmpty ? null : _rollCtrl.text.trim(),
      semester:   _semester,
    );
    if (!ok && mounted) {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join CHEA', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                Text('Use your institute email address',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                _label('Full Name'),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      hintText: 'Your full name',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.textMuted, size: 20)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Institute Email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 16),

                _label('Roll Number (optional)'),
                TextFormField(
                  controller: _rollCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      hintText: 'e.g. CH21B001',
                      prefixIcon: Icon(Icons.badge_outlined,
                          color: AppColors.textMuted, size: 20)),
                ),
                const SizedBox(height: 16),

                _label('Current Semester'),
                DropdownButtonFormField<int>(
                  value: _semester,
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  items: List.generate(8, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Semester ${i + 1}'),
                  )),
                  onChanged: (v) => setState(() => _semester = v ?? 1),
                ),
                const SizedBox(height: 16),

                _label('Password'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Min. 8 characters',
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CheaButton(
                  label: 'Create Account',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Only institute email domains are allowed.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.labelLarge),
  );
}
