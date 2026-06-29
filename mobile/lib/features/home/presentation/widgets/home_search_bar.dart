import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.md,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search articles, events, resources…',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: AppRadius.xs,
                  ),
                  child: Text('⌘ K',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.accent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
