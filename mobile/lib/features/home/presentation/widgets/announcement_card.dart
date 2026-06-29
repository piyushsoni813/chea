import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

// ── Category chip colour mapping ──────────────────────────────────────────────
Color _categoryColor(String category) {
  return switch (category) {
    'achievement'      => AppColors.success,
    'announcement'     => AppColors.accent,
    'department_news'  => const Color(0xFF0A84FF),
    'research'         => const Color(0xFFBF5AF2),
    'event'            => const Color(0xFFFF9F0A),
    _                  => AppColors.textMuted,
  };
}

String _categoryLabel(String category) =>
    category.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

// ── Single announcement card ──────────────────────────────────────────────────
class AnnouncementCard extends StatelessWidget {
  final ArticleSummary article;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(article.category);
    final dateStr = article.publishedAt != null
        ? _formatDate(article.publishedAt!)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color accent bar
            Container(
              width: 3,
              height: 54,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.full,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          _categoryLabel(article.category),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: color),
                        ),
                      ),
                      const Spacer(),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.excerpt != null &&
                      article.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.excerpt!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Read More',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.accent)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class AnnouncementSkeleton extends StatelessWidget {
  const AnnouncementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
