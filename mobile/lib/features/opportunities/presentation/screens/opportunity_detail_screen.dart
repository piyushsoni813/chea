import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OpportunityDetailScreen extends StatelessWidget {{
  final String id;
  const OpportunityDetailScreen({{super.key, required this.id}});
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Opportunity')),
      body: Center(child: Text('ID: $id', style: AppTextStyles.bodyMedium)),
    );
  }}
}}
