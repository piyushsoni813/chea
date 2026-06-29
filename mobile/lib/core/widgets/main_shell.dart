import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Maps each tab to a root-level route.
  static const _tabs = [
    (path: AppRoutes.home,          label: 'Home',          icon: Icons.home_rounded),
    (path: AppRoutes.news,          label: 'News',          icon: Icons.article_rounded),
    (path: 'fab',                   label: '',              icon: Icons.circle),   // FAB placeholder
    (path: AppRoutes.opportunities, label: 'Explore',       icon: Icons.work_rounded),
    (path: AppRoutes.resources,     label: 'Resources',     icon: Icons.folder_rounded),
    (path: AppRoutes.profile,       label: 'Profile',       icon: Icons.person_rounded),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].path == 'fab') continue;
      if (loc.startsWith(_tabs[i].path)) return i;
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
        onTap: (i) {
          if (_tabs[i].path != 'fab') {
            context.go(_tabs[i].path);
          }
        },
      ),
    );
  }
}

class _CheaBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _CheaBottomBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: List.generate(MainShell._tabs.length, (i) {
          final tab = MainShell._tabs[i];

          // Centre FAB
          if (tab.path == 'fab') {
            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  height: 64,
                  alignment: Alignment.center,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text('⚗️',
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
            );
          }

          final isSelected = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentDim : Colors.transparent,
                        borderRadius: AppRadius.full,
                      ),
                      child: Icon(tab.icon,
                          color: isSelected
                              ? AppColors.accent : AppColors.textMuted,
                          size: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(tab.label,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.accent : AppColors.textMuted)),
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
