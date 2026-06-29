import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius ?? AppRadius.sm,
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 180, borderRadius: AppRadius.md),
          SizedBox(height: 12),
          SkeletonBox(width: 80, height: 12),
          SizedBox(height: 8),
          SkeletonBox(height: 20),
          SizedBox(height: 6),
          SkeletonBox(height: 16, width: 200),
          SizedBox(height: 12),
          Row(children: [
            SkeletonBox(width: 60, height: 12),
            SizedBox(width: 12),
            SkeletonBox(width: 80, height: 12),
          ]),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(
                color: AppColors.surface, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 14,
                      decoration: const BoxDecoration(color: AppColors.surface,
                          borderRadius: AppRadius.xs)),
                  const SizedBox(height: 6),
                  Container(width: 200, height: 11,
                      decoration: const BoxDecoration(color: AppColors.surface,
                          borderRadius: AppRadius.xs)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
