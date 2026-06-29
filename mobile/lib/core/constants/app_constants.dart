class AppConstants {
  AppConstants._();

  // Storage keys
  static const kAccessToken    = 'access_token';
  static const kRefreshToken   = 'refresh_token';
  static const kUserRole       = 'user_role';
  static const kFcmToken       = 'fcm_token';

  // Hive box names
  static const hiveArticles       = 'articles';
  static const hiveOpportunities  = 'opportunities';
  static const hiveEvents         = 'events';
  static const hivePublications   = 'publications';
  static const hiveResources      = 'resources';

  // Pagination defaults
  static const defaultPageSize = 20;

  // Image placeholders
  static const placeholderUser    = 'assets/images/placeholder_user.png';
  static const placeholderCover   = 'assets/images/placeholder_cover.png';
  static const cheaLogoPath       = 'assets/images/chea_logo.png';

  // App info
  static const appName = 'CHEA';
  static const appTagline = 'Chemical Engineering Students Association';
}
