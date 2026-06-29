import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Reusable section header: bold title on the left, "See all →" on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See all',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.accent)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
