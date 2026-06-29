import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

// ── Type icon + colour ────────────────────────────────────────────────────────
({IconData icon, Color color}) _typeMeta(String type) => switch (type) {
  'magazine'      => (icon: Icons.auto_stories_rounded,      color: AppColors.accent),
  'gazette'       => (icon: Icons.newspaper_rounded,          color: const Color(0xFF34C759)),
  'annual_report' => (icon: Icons.bar_chart_rounded,          color: const Color(0xFF0A84FF)),
  'research_paper'=> (icon: Icons.science_outlined,           color: const Color(0xFFBF5AF2)),
  'newsletter'    => (icon: Icons.mark_email_read_outlined,   color: const Color(0xFFFF9F0A)),
  _               => (icon: Icons.description_outlined,       color: AppColors.textMuted),
};

// ── Single publication card ───────────────────────────────────────────────────
class PublicationCard extends StatelessWidget {
  final PublicationSummary publication;
  final VoidCallback onTap;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(publication.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            SizedBox(
              height: 170,
              width: double.infinity,
              child: publication.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: publication.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _PlaceholderCover(meta: meta),
                      errorWidget: (_, __, ___) =>
                          _PlaceholderCover(meta: meta),
                    )
                  : _PlaceholderCover(meta: meta),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.title,
                    style: AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    publication.academicYear,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 10),
                  // Open PDF button
                  GestureDetector(
                    onTap: () => _openPdf(publication.pdfUrl),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              size: 13, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text('Open PDF',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _PlaceholderCover extends StatelessWidget {
  final ({IconData icon, Color color}) meta;
  const _PlaceholderCover({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigh,
      child: Center(
        child: Icon(meta.icon, size: 40, color: meta.color.withOpacity(0.5)),
      ),
    );
  }
}

// ── Horizontal scroll section ─────────────────────────────────────────────────
class PublicationsSection extends StatelessWidget {
  final List<PublicationSummary> publications;
  final VoidCallback onTap;

  const PublicationsSection({
    super.key,
    required this.publications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
          ),
          child: Text('No publications yet',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );
    }
    return SizedBox(
      height: 272,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: publications.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => PublicationCard(
          publication: publications[i],
          onTap: onTap,
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class PublicationsSectionSkeleton extends StatelessWidget {
  const PublicationsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 272,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceHigh,
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lg,
            ),
          ),
        ),
      ),
    );
  }
}
