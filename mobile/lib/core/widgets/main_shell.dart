import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  static const _tabs = [
    (
      path: AppRoutes.home,
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    (
      path: AppRoutes.news,
      label: 'News',
      icon: Icons.article_rounded,
    ),
    (
      path: 'fab',
      label: '',
      icon: Icons.circle,
    ),
    (
      path: AppRoutes.opportunities,
      label: 'Explore',
      icon: Icons.work_rounded,
    ),
    (
      path: AppRoutes.resources,
      label: 'Resources',
      icon: Icons.folder_rounded,
    ),
    (
      path: AppRoutes.profile,
      label: 'Profile',
      icon: Icons.person_rounded,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].path == 'fab') continue;

      if (location.startsWith(_tabs[i].path)) {
        return i;
      }
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: _CheaBottomBar(
        selectedIndex: selected,
        onTap: (index) {
          if (_tabs[index].path != 'fab') {
            context.go(_tabs[index].path);
          }
        },
      ),
    );
  }
}

class _CheaBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CheaBottomBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: List.generate(MainShell._tabs.length, (i) {
          final tab = MainShell._tabs[i];

          // Floating Action Button
          if (tab.path == 'fab') {
            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  height: 64,
                  alignment: Alignment.center,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.science,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final isSelected = selectedIndex == i;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentDim
                              : Colors.transparent,
                          borderRadius: AppRadius.full,
                        ),
                        child: Icon(
                          tab.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}