import 'package:dio/dio.dart';
import '../models/home_models.dart';
import '../../domain/entities/home_entities.dart';

/// All network calls needed by the Home screen.
/// Queries are deliberately small (size=5) — we only need highlights.
class HomeRemoteDatasource {
  final Dio _dio;
  HomeRemoteDatasource(this._dio);

  /// Latest announcements / news (kind=news, sorted by newest).
  Future<List<ArticleSummary>> fetchAnnouncements() async {
    final r = await _dio.get('/articles', queryParameters: {
      'kind': 'news',
      'page': 1,
      'size': 5,
    });
    final items = (r.data['items'] as List);
    return items
        .map((e) => ArticleSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Featured blog — the single article marked is_featured=true with kind=blog.
  Future<ArticleSummary?> fetchFeaturedBlog() async {
    final r = await _dio.get('/articles', queryParameters: {
      'kind':     'blog',
      'featured': true,
      'page':     1,
      'size':     1,
    });
    final items = (r.data['items'] as List);
    if (items.isEmpty) return null;
    return ArticleSummaryModel.fromJson(items.first as Map<String, dynamic>);
  }

  /// Upcoming events (soonest first).
  Future<List<EventSummary>> fetchUpcomingEvents() async {
    final r = await _dio.get('/events', queryParameters: {
      'scope': 'upcoming',
      'page':  1,
      'size':  5,
    });
    final items = (r.data['items'] as List);
    return items
        .map((e) => EventSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Latest active opportunities filtered by type.
  Future<List<OpportunitySummary>> fetchLatestOpportunities() async {
    final r = await _dio.get('/opportunities', queryParameters: {
      'sort':   'newest',
      'active': true,
      'page':   1,
      'size':   6,
    });
    final items = (r.data['items'] as List);
    return items
        .map((e) =>
            OpportunitySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Most recent publications (any type).
  Future<List<PublicationSummary>> fetchLatestPublications() async {
    final r = await _dio.get('/publications', queryParameters: {
      'page': 1,
      'size': 4,
    });
    final items = (r.data['items'] as List);
    return items
        .map((e) =>
            PublicationSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Unread notification count for the badge.
  Future<int> fetchUnreadCount() async {
    final r = await _dio.get('/notifications/unread-count');
    return (r.data['unread'] as int?) ?? 0;
  }
}
