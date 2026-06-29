import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contacts')),
      body: Center(
        child: Text('Contacts', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
