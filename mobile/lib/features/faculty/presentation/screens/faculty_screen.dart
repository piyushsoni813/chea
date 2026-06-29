import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Faculty')),
      body: Center(
        child: Text('Faculty', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
