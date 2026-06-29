import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FacultyDetailScreen extends StatelessWidget {{
  final String id;
  const FacultyDetailScreen({{super.key, required this.id}});
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Faculty Profile')),
      body: Center(child: Text('ID: $id', style: AppTextStyles.bodyMedium)),
    );
  }}
}}
