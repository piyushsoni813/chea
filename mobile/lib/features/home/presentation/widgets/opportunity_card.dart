import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

// ── Type metadata ─────────────────────────────────────────────────────────────
({Color color, IconData icon, String label}) _typeMeta(String type) {
  return switch (type) {
    'internship'  => (color: AppColors.internship,  icon: Icons.work_outline_rounded,           label: 'Internship'),
    'placement'   => (color: AppColors.placement,   icon: Icons.business_center_outlined,       label: 'Placement'),
    'project'     => (color: AppColors.project,     icon: Icons.science_outlined,               label: 'Project'),
    'research'    => (color: AppColors.research,    icon: Icons.biotech_outlined,               label: 'Research'),
    'scholarship' => (color: AppColors.scholarship, icon: Icons.school_outlined,                label: 'Scholarship'),
    _             => (color: AppColors.textMuted,   icon: Icons.work_outline_rounded,           label: type),
  };
}

// ── Deadline formatting ───────────────────────────────────────────────────────
String _deadlineText(DateTime? deadline) {
  if (deadline == null) return 'Open';
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Expired';
  if (diff.inDays == 0) return 'Closes today';
  if (diff.inDays == 1) return 'Closes tomorrow';
  if (diff.inDays <= 7) return 'Closes in ${diff.inDays}d';
  final months = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
  return 'Due ${deadline.day} ${months[deadline.month - 1]}';
}

Color _deadlineColor(DateTime? deadline) {
  if (deadline == null) return AppColors.success;
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return AppColors.error;
  if (diff.inDays <= 3) return AppColors.error;
  if (diff.inDays <= 7) return AppColors.warning;
  return AppColors.success;
}

// ── Single opportunity card ───────────────────────────────────────────────────
class OpportunityCard extends StatelessWidget {
  final OpportunitySummary opportunity;
  final VoidCallback onTap;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta         = _typeMeta(opportunity.type);
    final deadlineText = _deadlineText(opportunity.deadline);
    final deadlineCol  = _deadlineColor(opportunity.deadline);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo or type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.15),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.role,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        opportunity.company,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.15),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(meta.label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: meta.color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Location
                if (opportunity.location != null ||
                    opportunity.isRemote) ...[
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(
                    opportunity.isRemote
                        ? 'Remote'
                        : opportunity.location!,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: 12),
                ],
                // Deadline
                const Icon(Icons.schedule_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(deadlineText,
                    style: AppTextStyles.caption
                        .copyWith(color: deadlineCol)),
                const Spacer(),
                // Apply button
                if (opportunity.applyUrl != null)
                  GestureDetector(
                    onTap: () => _launchUrl(opportunity.applyUrl!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Text('Apply',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class OpportunitySectionSkeleton extends StatelessWidget {
  const OpportunitySectionSkeleton({super.key});

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
