import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FormsScreen extends StatelessWidget {
  const FormsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forms')),
      body: Center(
        child: Text('Forms', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
