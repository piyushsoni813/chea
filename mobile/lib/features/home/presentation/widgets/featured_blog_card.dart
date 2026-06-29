import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

class FeaturedBlogCard extends StatelessWidget {
  final ArticleSummary article;
  final VoidCallback onTap;

  const FeaturedBlogCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            if (article.coverImageUrl != null)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: article.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppColors.surfaceHigh),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceHigh,
                              child: const Icon(Icons.article_rounded,
                                  color: AppColors.textMuted, size: 40)),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.surface.withOpacity(0.8),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Featured badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadius.full,
                        ),
                        child: Text('⭐ Featured',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Author avatar + name
                      if (article.author != null) ...[
                        _AuthorAvatar(author: article.author!),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.author!.fullName,
                                  style: AppTextStyles.labelMedium,
                                  overflow: TextOverflow.ellipsis),
                              Text('Author',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ] else
                        const Spacer(),
                      // Stats
                      _Stat(
                          icon: Icons.schedule_outlined,
                          label: '${article.readingMinutes} min'),
                      const SizedBox(width: 14),
                      _Stat(
                          icon: Icons.favorite_outline_rounded,
                          label: article.likeCount.toString()),
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
}

class _AuthorAvatar extends StatelessWidget {
  final ArticleAuthor author;
  const _AuthorAvatar({required this.author});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: ClipOval(
        child: author.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: author.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initials,
                errorWidget: (_, __, ___) => _initials,
              )
            : _initials,
      ),
    );
  }

  Widget get _initials => Container(
    color: AppColors.accentDim,
    alignment: Alignment.center,
    child: Text(
      author.fullName.isNotEmpty ? author.fullName[0].toUpperCase() : '?',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent),
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class FeaturedBlogSkeleton extends StatelessWidget {
  const FeaturedBlogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHigh,
      child: Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
        ),
      ),
    );
  }
}
