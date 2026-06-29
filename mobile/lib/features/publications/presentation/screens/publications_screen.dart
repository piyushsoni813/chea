import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PublicationsScreen extends StatelessWidget {
  const PublicationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Publications')),
      body: Center(
        child: Text('Publications', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
