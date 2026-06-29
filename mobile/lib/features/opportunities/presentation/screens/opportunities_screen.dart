import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Opportunities')),
      body: Center(
        child: Text('Opportunities', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
