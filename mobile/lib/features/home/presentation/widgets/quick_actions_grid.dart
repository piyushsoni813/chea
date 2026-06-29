import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _Action(this.label, this.icon, this.color, this.route);
}

const _actions = [
  _Action('Events',      Icons.event_rounded,          Color(0xFF0A84FF), '/events'),
  _Action('Faculty',     Icons.person_pin_rounded,      Color(0xFFBF5AF2), '/faculty'),
  _Action('Publications',Icons.menu_book_rounded,        Color(0xFFFF9F0A), '/publications'),
  _Action('Gazette',     Icons.newspaper_rounded,        Color(0xFF34C759), '/publications'),
  _Action('Resources',   Icons.folder_special_rounded,   Color(0xFFFF375F), '/resources'),
  _Action('Forms',       Icons.assignment_rounded,        Color(0xFF64D2FF), '/forms'),
  _Action('Resume Bank', Icons.work_history_rounded,      Color(0xFFFFD60A), '/resources'),
  _Action('Contact Us',  Icons.support_agent_rounded,     Color(0xFFFF7A00), '/contacts'),
];

class QuickActionsGrid extends StatelessWidget {
  final void Function(String route) onNavigate;

  const QuickActionsGrid({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 96,
        ),
        itemBuilder: (_, i) => _QuickActionCard(
          action: _actions[i],
          onTap: () => onNavigate(_actions[i].route),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final _Action action;
  final VoidCallback onTap;
  const _QuickActionCard({required this.action, required this.onTap});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(a.icon, color: a.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                a.label,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class QuickActionsGridSkeleton extends StatelessWidget {
  const QuickActionsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 96,
        ),
        itemBuilder: (_, __) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.md,
          ),
        ),
      ),
    );
  }
}
