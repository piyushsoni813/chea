import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Resources')),
      body: Center(
        child: Text('Resources', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
