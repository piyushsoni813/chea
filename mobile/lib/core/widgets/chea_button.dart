import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CheaButtonVariant { primary, secondary, ghost, danger }

class CheaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CheaButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? height;

  const CheaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CheaButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      CheaButtonVariant.primary   => (AppColors.accent, AppColors.onAccent, null),
      CheaButtonVariant.secondary => (AppColors.surface, AppColors.textPrimary,
                                       AppColors.border),
      CheaButtonVariant.ghost     => (Colors.transparent, AppColors.accent, null),
      CheaButtonVariant.danger    => (AppColors.error, Colors.white, null),
    };

    Widget child = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
                color: fg, strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.labelLarge.copyWith(color: fg)),
            ],
          );

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height ?? 50,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.md,
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.md,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          splashColor: fg.withOpacity(0.1),
          child: Center(child: child),
        ),
      ),
    );

    return btn;
  }
}
