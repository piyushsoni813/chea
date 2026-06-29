import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const background  = Color(0xFF0B0B0D);
  static const surface     = Color(0xFF1E1E22);
  static const surfaceHigh = Color(0xFF2C2C30);
  static const accent      = Color(0xFFFF7A00);
  static const accentDim   = Color(0x33FF7A00);
  static const onAccent    = Colors.white;
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFAAAAAA);
  static const textMuted   = Color(0xFF666670);
  static const border      = Color(0xFF2C2C30);
  static const success     = Color(0xFF34C759);
  static const warning     = Color(0xFFFFD60A);
  static const error       = Color(0xFFFF453A);

  static const internship  = Color(0xFF0A84FF);
  static const placement   = Color(0xFF34C759);
  static const research    = Color(0xFFBF5AF2);
  static const project     = Color(0xFFFF9F0A);
  static const scholarship = Color(0xFFFF375F);
}

class AppRadius {
  AppRadius._();
  static const xs  = BorderRadius.all(Radius.circular(8));
  static const sm  = BorderRadius.all(Radius.circular(12));
  static const md  = BorderRadius.all(Radius.circular(16));
  static const lg  = BorderRadius.all(Radius.circular(20));
  static const xl  = BorderRadius.all(Radius.circular(28));
  static const full = BorderRadius.all(Radius.circular(999));
}

class AppSpacing {
  AppSpacing._();
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

// ── Text styles ───────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final displayLarge  = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1);
  static final displayMedium = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15);
  static final titleLarge    = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2);
  static final titleMedium   = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600, height: 1.25);
  static final titleSmall    = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);
  static final bodyLarge     = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static final bodyMedium    = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySmall     = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static final labelLarge    = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static final labelMedium   = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2);
  static final labelSmall    = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3);
  static final caption       = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary:          AppColors.accent,
    onPrimary:        AppColors.onAccent,
    secondary:        AppColors.accent,
    onSecondary:      AppColors.onAccent,
    surface:          AppColors.surface,
    onSurface:        AppColors.textPrimary,
    error:            AppColors.error,
    onError:          Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',

    // ── AppBar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: AppTextStyles.titleMedium,
      centerTitle: false,
    ),

    // ── Cards ────────────────────────────────────────────────────────────────
    cardTheme: const CardTheme(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      clipBehavior: Clip.antiAlias,
    ),

    // ── Navigation bar ───────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accentDim,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppTextStyles.labelMedium.copyWith(color: AppColors.accent)
              : AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? const IconThemeData(color: AppColors.accent, size: 24)
              : const IconThemeData(color: AppColors.textMuted, size: 24)),
    ),

    // ── Input ────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Elevated button ──────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // ── Text button ──────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Outlined button ──────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Chip ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentDim,
      labelStyle: AppTextStyles.labelMedium,
      side: const BorderSide(color: AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0,
    ),

    // ── Bottom sheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── Snack bar ────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: AppTextStyles.bodyMedium,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Tab bar ──────────────────────────────────────────────────────────────
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.labelLarge,
      dividerColor: AppColors.border,
    ),

    textTheme: TextTheme(
      displayLarge:  AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      titleLarge:    AppTextStyles.titleLarge,
      titleMedium:   AppTextStyles.titleMedium,
      titleSmall:    AppTextStyles.titleSmall,
      bodyLarge:     AppTextStyles.bodyLarge,
      bodyMedium:    AppTextStyles.bodyMedium,
      bodySmall:     AppTextStyles.bodySmall,
      labelLarge:    AppTextStyles.labelLarge,
      labelMedium:   AppTextStyles.labelMedium,
      labelSmall:    AppTextStyles.labelSmall,
    ),
  );
}
