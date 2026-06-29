import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('News & Blogs')),
      body: Center(
        child: Text('News & Blogs', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
