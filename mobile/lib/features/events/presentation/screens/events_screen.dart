import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Events')),
      body: Center(
        child: Text('Events', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
