import 'package:flutter/foundation.dart';

// ── Article summary (used for announcements + featured blog) ─────────────────
@immutable
class ArticleSummary {
  final String id;
  final String title;
  final String slug;
  final String kind; // 'news' | 'blog'
  final String category;
  final String? excerpt;
  final String? coverImageUrl;
  final List<String> tags;
  final int readingMinutes;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime? publishedAt;
  final ArticleAuthor? author;

  const ArticleSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.kind,
    required this.category,
    this.excerpt,
    this.coverImageUrl,
    required this.tags,
    required this.readingMinutes,
    required this.isFeatured,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    this.publishedAt,
    this.author,
  });
}

@immutable
class ArticleAuthor {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const ArticleAuthor({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });
}

// ── Event summary ─────────────────────────────────────────────────────────────
@immutable
class EventSummary {
  final String id;
  final String title;
  final String slug;
  final String type;
  final String? bannerUrl;
  final String? venue;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool registrationOpen;
  final int registeredCount;
  final int? capacity;

  const EventSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.type,
    this.bannerUrl,
    this.venue,
    required this.startsAt,
    this.endsAt,
    required this.registrationOpen,
    required this.registeredCount,
    this.capacity,
  });

  Duration get timeUntil => startsAt.difference(DateTime.now());
  bool get isUpcoming => startsAt.isAfter(DateTime.now());
}

// ── Opportunity summary ───────────────────────────────────────────────────────
@immutable
class OpportunitySummary {
  final String id;
  final String type; // internship | placement | project | research | scholarship
  final String company;
  final String role;
  final String? location;
  final bool isRemote;
  final String? compensation;
  final String? companyLogoUrl;
  final String? applyUrl;
  final DateTime? deadline;
  final bool isActive;

  const OpportunitySummary({
    required this.id,
    required this.type,
    required this.company,
    required this.role,
    this.location,
    required this.isRemote,
    this.compensation,
    this.companyLogoUrl,
    this.applyUrl,
    this.deadline,
    required this.isActive,
  });

  bool get isDeadlineSoon {
    if (deadline == null) return false;
    final diff = deadline!.difference(DateTime.now());
    return diff.isNegative ? false : diff.inDays <= 7;
  }

  bool get isExpired {
    if (deadline == null) return false;
    return deadline!.isBefore(DateTime.now());
  }
}

// ── Publication summary ───────────────────────────────────────────────────────
@immutable
class PublicationSummary {
  final String id;
  final String title;
  final String type; // magazine | gazette | research_paper | annual_report | newsletter
  final String academicYear;
  final String? coverImageUrl;
  final String pdfUrl;
  final int downloadCount;
  final DateTime? publishedAt;

  const PublicationSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.academicYear,
    this.coverImageUrl,
    required this.pdfUrl,
    required this.downloadCount,
    this.publishedAt,
  });
}

// ── Aggregate home data ───────────────────────────────────────────────────────
@immutable
class HomeData {
  final List<ArticleSummary> announcements;
  final List<EventSummary> upcomingEvents;
  final ArticleSummary? featuredBlog;
  final List<OpportunitySummary> latestOpportunities;
  final List<PublicationSummary> latestPublications;
  final int unreadNotifications;

  const HomeData({
    required this.announcements,
    required this.upcomingEvents,
    this.featuredBlog,
    required this.latestOpportunities,
    required this.latestPublications,
    required this.unreadNotifications,
  });

  HomeData copyWith({
    List<ArticleSummary>? announcements,
    List<EventSummary>? upcomingEvents,
    ArticleSummary? featuredBlog,
    bool clearFeaturedBlog = false,
    List<OpportunitySummary>? latestOpportunities,
    List<PublicationSummary>? latestPublications,
    int? unreadNotifications,
  }) =>
      HomeData(
        announcements: announcements ?? this.announcements,
        upcomingEvents: upcomingEvents ?? this.upcomingEvents,
        featuredBlog: clearFeaturedBlog ? null : featuredBlog ?? this.featuredBlog,
        latestOpportunities: latestOpportunities ?? this.latestOpportunities,
        latestPublications: latestPublications ?? this.latestPublications,
        unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      );
}
