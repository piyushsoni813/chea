import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Text('Search', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
