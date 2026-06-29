import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/announcement_card.dart';
import '../widgets/event_card.dart';
import '../widgets/featured_blog_card.dart';
import '../widgets/home_error_banner.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/opportunity_card.dart';
import '../widgets/publication_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/welcome_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helper ──────────────────────────────────────────────────────
  void _go(String route) => context.go(route);

  // ── Notification badge ─────────────────────────────────────────────────────
  Widget _notificationButton(int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.textPrimary,
          iconSize: 26,
          onPressed: () => _go(AppRoutes.notifications),
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final unread    = ref.watch(unreadCountProvider);
    final user      = authState.user;

    // Start fade-in once data arrives
    if (homeState.status == HomeLoadStatus.success && !_fadeCtrl.isCompleted) {
      _fadeCtrl.forward();
    }

    final isLoading = homeState.status == HomeLoadStatus.loading;
    final hasData   = homeState.hasData;
    final data      = homeState.data;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          displacement: 80,
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // ── App bar ───────────────────────────────────────────────────
              SliverAppBar(
                pinned: false,
                floating: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚗️  CHEA',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.accent),
                    ),
                    Text(
                      'Chemical Engineering',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                actions: [
                  if (homeState.isRefreshing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  _notificationButton(unread),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Body ──────────────────────────────────────────────────────
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // 1. Welcome card
                  if (user != null) ...[
                    WelcomeCard(user: user),
                    const SizedBox(height: 20),
                  ],

                  // 2. Search bar
                  HomeSearchBar(onTap: () => _go(AppRoutes.search)),
                  const SizedBox(height: 24),

                  // 3. Quick actions
                  SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 14),
                  isLoading
                      ? const QuickActionsGridSkeleton()
                      : QuickActionsGrid(onNavigate: _go),
                  const SizedBox(height: 28),

                  // ── Error banner (full failure, no cache) ─────────────────
                  if (!hasData &&
                      homeState.status == HomeLoadStatus.error &&
                      homeState.failure != null) ...[
                    HomeErrorBanner(
                      failure: homeState.failure!,
                      onRetry: () =>
                          ref.read(homeProvider.notifier).load(),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ── Sections (visible once data is available) ─────────────
                  FadeTransition(
                    opacity: hasData ? _fadeAnim : const AlwaysStoppedAnimation(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasData) ...[
                          // 4. Announcements
                          SectionHeader(
                            title: 'Announcements',
                            onSeeAll: () => _go(AppRoutes.news),
                          ),
                          const SizedBox(height: 14),
                          if (data!.announcements.isEmpty)
                            _EmptySection(
                                icon: Icons.campaign_outlined,
                                label: 'No announcements')
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: data.announcements
                                    .map((a) => AnnouncementCard(
                                          article: a,
                                          onTap: () => context.go(
                                              '/news/${a.slug}'),
                                        ))
                                    .toList(),
                              ),
                            ),
                          const SizedBox(height: 28),

                          // 5. Upcoming events
                          SectionHeader(
                            title: 'Upcoming Events',
                            onSeeAll: () => _go(AppRoutes.events),
                          ),
                          const SizedBox(height: 14),
                          data.upcomingEvents.isEmpty
                              ? _EmptySection(
                                  icon: Icons.event_busy_outlined,
                                  label: 'No upcoming events')
                              : EventsSection(
                                  events: data.upcomingEvents,
                                  onEventTap: (slug) =>
                                      context.go('/events/$slug'),
                                ),
                          const SizedBox(height: 28),

                          // 6. Featured blog
                          if (data.featuredBlog != null) ...[
                            SectionHeader(
                              title: 'Featured Blog',
                              onSeeAll: () => _go(AppRoutes.news),
                            ),
                            const SizedBox(height: 14),
                            FeaturedBlogCard(
                              article: data.featuredBlog!,
                              onTap: () => context.go(
                                  '/news/${data.featuredBlog!.slug}'),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 7. Latest opportunities
                          SectionHeader(
                            title: 'Latest Opportunities',
                            onSeeAll: () => _go(AppRoutes.opportunities),
                          ),
                          const SizedBox(height: 14),
                          data.latestOpportunities.isEmpty
                              ? _EmptySection(
                                  icon: Icons.work_off_outlined,
                                  label: 'No active opportunities')
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    children: data.latestOpportunities
                                        .take(4)
                                        .map((o) => OpportunityCard(
                                              opportunity: o,
                                              onTap: () => context.go(
                                                  '/opportunities/${o.id}'),
                                            ))
                                        .toList(),
                                  ),
                                ),
                          const SizedBox(height: 28),

                          // 8. Latest publications
                          SectionHeader(
                            title: 'Publications',
                            onSeeAll: () => _go(AppRoutes.publications),
                          ),
                          const SizedBox(height: 14),
                          data.latestPublications.isEmpty
                              ? _EmptySection(
                                  icon: Icons.menu_book_outlined,
                                  label: 'No publications yet')
                              : PublicationsSection(
                                  publications: data.latestPublications,
                                  onTap: () => _go(AppRoutes.publications),
                                ),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),

                  // ── Skeleton sections (while loading, no data yet) ─────────
                  if (isLoading && !hasData) ...[
                    SectionHeader(title: 'Announcements'),
                    const SizedBox(height: 14),
                    const AnnouncementSkeleton(),
                    const SizedBox(height: 28),
                    SectionHeader(title: 'Upcoming Events'),
                    const SizedBox(height: 14),
                    const EventsSectionSkeleton(),
                    const SizedBox(height: 28),
                    SectionHeader(title: 'Featured Blog'),
                    const SizedBox(height: 14),
                    const FeaturedBlogSkeleton(),
                    const SizedBox(height: 28),
                    SectionHeader(title: 'Latest Opportunities'),
                    const SizedBox(height: 14),
                    const OpportunitySectionSkeleton(),
                    const SizedBox(height: 28),
                    SectionHeader(title: 'Publications'),
                    const SizedBox(height: 14),
                    const PublicationsSectionSkeleton(),
                    const SizedBox(height: 40),
                  ],

                  // Bottom padding for the nav bar
                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline empty state ─────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptySection({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
