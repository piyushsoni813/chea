import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart';

class WelcomeCard extends StatelessWidget {
  final User user;

  const WelcomeCard({super.key, required this.user});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final sp = user.studentProfile;
    final firstName = user.fullName.split(' ').first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E22), Color(0xFF2A1A0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        firstName,
                        style: AppTextStyles.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.waving_hand_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _InfoChip(
                  icon: Icons.school_outlined,
                  label: 'Chemical Engineering',
                ),
                if (sp?.semester != null) ...[
                  const SizedBox(height: 6),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Semester ${sp!.semester}',
                  ),
                ],
                if (sp?.rollNumber != null) ...[
                  const SizedBox(height: 6),
                  _InfoChip(
                    icon: Icons.badge_outlined,
                    label: sp!.rollNumber!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Profile avatar ───────────────────────────────────────────────
          _Avatar(avatarUrl: user.avatarUrl, name: user.fullName),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.accent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  const _Avatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _Initials(name: name),
                errorWidget:  (_, __, ___) => _Initials(name: name),
              )
            : _Initials(name: name),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentDim,
      alignment: Alignment.center,
      child: Text(initials,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.accent)),
    );
  }
}
