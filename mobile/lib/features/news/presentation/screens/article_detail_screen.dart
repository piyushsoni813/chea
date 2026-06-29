import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String slug;

  const ArticleDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Article')),
      body: Center(
        child: Text(
          'Slug: $slug',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}