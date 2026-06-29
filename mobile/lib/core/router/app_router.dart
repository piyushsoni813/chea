import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/news/presentation/screens/news_screen.dart';
import '../../features/news/presentation/screens/article_detail_screen.dart';
import '../../features/opportunities/presentation/screens/opportunities_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/publications/presentation/screens/publications_screen.dart';
import '../../features/resources/presentation/screens/resources_screen.dart';
import '../../features/faculty/presentation/screens/faculty_screen.dart';
import '../../features/faculty/presentation/screens/faculty_detail_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/forms/presentation/screens/forms_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../widgets/main_shell.dart';

// Route names
class AppRoutes {
  static const login         = '/login';
  static const register      = '/register';
  static const home          = '/';
  static const news          = '/news';
  static const articleDetail = '/news/:slug';
  static const opportunities = '/opportunities';
  static const opportunityDetail = '/opportunities/:id';
  static const events        = '/events';
  static const eventDetail   = '/events/:slug';
  static const publications  = '/publications';
  static const resources     = '/resources';
  static const faculty       = '/faculty';
  static const facultyDetail = '/faculty/:id';
  static const contacts      = '/contacts';
  static const forms         = '/forms';
  static const profile       = '/profile';
  static const notifications = '/notifications';
  static const search        = '/search';
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.unknown;
      if (isLoading) return null;
      final onAuth = state.matchedLocation == AppRoutes.login ||
                     state.matchedLocation == AppRoutes.register;
      if (!isAuth && !onAuth) return AppRoutes.login;
      if (isAuth && onAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,
              builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.news,
              builder: (_, __) => const NewsScreen(),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (_, s) =>
                      ArticleDetailScreen(slug: s.pathParameters['slug']!),
                ),
              ]),
          GoRoute(path: AppRoutes.opportunities,
              builder: (_, __) => const OpportunitiesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => OpportunityDetailScreen(
                      id: s.pathParameters['id']!),
                ),
              ]),
          GoRoute(path: AppRoutes.resources,
              builder: (_, __) => const ResourcesScreen()),
          GoRoute(path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen()),
          // Extra routes still inside the shell (no nav bar highlight)
          GoRoute(path: AppRoutes.events,
              builder: (_, __) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (_, s) =>
                      EventDetailScreen(slug: s.pathParameters['slug']!),
                ),
              ]),
          GoRoute(path: AppRoutes.publications,
              builder: (_, __) => const PublicationsScreen()),
          GoRoute(path: AppRoutes.faculty,
              builder: (_, __) => const FacultyScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) =>
                      FacultyDetailScreen(id: s.pathParameters['id']!),
                ),
              ]),
          GoRoute(path: AppRoutes.contacts,
              builder: (_, __) => const ContactsScreen()),
          GoRoute(path: AppRoutes.forms,
              builder: (_, __) => const FormsScreen()),
          GoRoute(path: AppRoutes.notifications,
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.search,
              builder: (_, __) => const SearchScreen()),
        ],
      ),
    ],
  );
});
