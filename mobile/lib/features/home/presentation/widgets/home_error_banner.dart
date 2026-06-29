import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/failures.dart';

class HomeErrorBanner extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const HomeErrorBanner({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure is NetworkFailure;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            isNetwork ? 'No Internet Connection' : 'Something went wrong',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            failure.message,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppRadius.md,
              ),
              child: Text('Try again',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
