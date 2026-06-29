import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/home_entities.dart';
import '../datasources/home_remote_datasource.dart';
import '../datasources/home_local_datasource.dart';
import '../models/home_models.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_response.dart';

class HomeRepository {
  final HomeRemoteDatasource _remote;
  final HomeLocalDatasource _local;

  HomeRepository(this._remote, this._local);

  /// Cache-first fetch. Sequence:
  ///   1. Return cached data immediately if it exists (fast UI).
  ///   2. If cache is stale or missing, fetch from network.
  ///   3. On success, write new cache and return fresh data.
  ///   4. On network failure with valid cache → return cache with a soft flag.
  Future<ApiResult<HomeData>> getHomeData({bool forceRefresh = false}) async {
    final hasCached = await _local.hasCachedData();
    final isStale   = await _local.isCacheStale();

    // Serve fresh if cache exists and is not stale.
    if (hasCached && !isStale && !forceRefresh) {
      final cached = await _local.getCachedHomeData();
      if (cached != null) {
        return ApiResult.success(_fromCache(cached));
      }
    }

    // Fetch fresh data.
    try {
      final results = await Future.wait([
        _remote.fetchAnnouncements(),
        _remote.fetchFeaturedBlog(),
        _remote.fetchUpcomingEvents(),
        _remote.fetchLatestOpportunities(),
        _remote.fetchLatestPublications(),
        _remote.fetchUnreadCount(),
      ]);

      final announcements  = results[0]  as List<ArticleSummary>;
      final featuredBlog   = results[1]  as ArticleSummary?;
      final events         = results[2]  as List<EventSummary>;
      final opportunities  = results[3]  as List<OpportunitySummary>;
      final publications   = results[4]  as List<PublicationSummary>;
      final unread         = results[5]  as int;

      final homeData = HomeData(
        announcements:       announcements,
        upcomingEvents:      events,
        featuredBlog:        featuredBlog,
        latestOpportunities: opportunities,
        latestPublications:  publications,
        unreadNotifications: unread,
      );

      await _local.cacheHomeData(_toCache(homeData));
      return ApiResult.success(homeData);
    } on DioException catch (e) {
      // Network failed — serve stale cache if available.
      if (hasCached) {
        final cached = await _local.getCachedHomeData();
        if (cached != null) return ApiResult.success(_fromCache(cached));
      }
      return ApiResult.failed(_mapDioError(e));
    } catch (e) {
      if (hasCached) {
        final cached = await _local.getCachedHomeData();
        if (cached != null) return ApiResult.success(_fromCache(cached));
      }
      return ApiResult.failed(UnknownFailure(e.toString()));
    }
  }

  // ── Cache serialisation helpers ─────────────────────────────────────────────
  Map<String, dynamic> _toCache(HomeData d) => {
    'announcements':       d.announcements.map(_articleToMap).toList(),
    'upcoming_events':     d.upcomingEvents.map(_eventToMap).toList(),
    'featured_blog':       d.featuredBlog == null ? null : _articleToMap(d.featuredBlog!),
    'latest_opportunities':d.latestOpportunities.map(_oppToMap).toList(),
    'latest_publications': d.latestPublications.map(_pubToMap).toList(),
    'unread_notifications':d.unreadNotifications,
  };

  HomeData _fromCache(Map<String, dynamic> m) => HomeData(
    announcements: (m['announcements'] as List)
        .map((e) => ArticleSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    upcomingEvents: (m['upcoming_events'] as List)
        .map((e) => EventSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    featuredBlog: m['featured_blog'] == null
        ? null
        : ArticleSummaryModel.fromJson(m['featured_blog'] as Map<String, dynamic>),
    latestOpportunities: (m['latest_opportunities'] as List)
        .map((e) => OpportunitySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    latestPublications: (m['latest_publications'] as List)
        .map((e) => PublicationSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    unreadNotifications: m['unread_notifications'] as int? ?? 0,
  );

  Map<String, dynamic> _articleToMap(ArticleSummary a) => {
    'id': a.id, 'title': a.title, 'slug': a.slug, 'kind': a.kind,
    'category': a.category, 'excerpt': a.excerpt,
    'cover_image_url': a.coverImageUrl,
    'tags': a.tags, 'reading_minutes': a.readingMinutes,
    'is_featured': a.isFeatured, 'view_count': a.viewCount,
    'like_count': a.likeCount, 'comment_count': a.commentCount,
    'published_at': a.publishedAt?.toIso8601String(),
    'author': a.author == null ? null : {
      'id': a.author!.id, 'full_name': a.author!.fullName,
      'avatar_url': a.author!.avatarUrl,
    },
  };

  Map<String, dynamic> _eventToMap(EventSummary e) => {
    'id': e.id, 'title': e.title, 'slug': e.slug, 'type': e.type,
    'banner_url': e.bannerUrl, 'venue': e.venue,
    'starts_at': e.startsAt.toIso8601String(),
    'ends_at': e.endsAt?.toIso8601String(),
    'registration_open': e.registrationOpen,
    'registered_count': e.registeredCount, 'capacity': e.capacity,
  };

  Map<String, dynamic> _oppToMap(OpportunitySummary o) => {
    'id': o.id, 'type': o.type, 'company': o.company, 'role': o.role,
    'location': o.location, 'is_remote': o.isRemote,
    'compensation': o.compensation, 'company_logo_url': o.companyLogoUrl,
    'apply_url': o.applyUrl, 'deadline': o.deadline?.toIso8601String(),
    'is_active': o.isActive,
  };

  Map<String, dynamic> _pubToMap(PublicationSummary p) => {
    'id': p.id, 'title': p.title, 'type': p.type,
    'academic_year': p.academicYear, 'cover_image_url': p.coverImageUrl,
    'pdf_url': p.pdfUrl, 'download_count': p.downloadCount,
    'published_at': p.publishedAt?.toIso8601String(),
  };

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(
      e.response?.data?['detail']?.toString() ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
