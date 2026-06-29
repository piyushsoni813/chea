import '../../domain/entities/home_entities.dart';

// ── Article ───────────────────────────────────────────────────────────────────
class ArticleSummaryModel extends ArticleSummary {
  const ArticleSummaryModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.kind,
    required super.category,
    super.excerpt,
    super.coverImageUrl,
    required super.tags,
    required super.readingMinutes,
    required super.isFeatured,
    required super.viewCount,
    required super.likeCount,
    required super.commentCount,
    super.publishedAt,
    super.author,
  });

  factory ArticleSummaryModel.fromJson(Map<String, dynamic> j) {
    final authorJson = j['author'] as Map<String, dynamic>?;
    return ArticleSummaryModel(
      id:             j['id']              as String,
      title:          j['title']           as String,
      slug:           j['slug']            as String,
      kind:           j['kind']            as String,
      category:       j['category']        as String,
      excerpt:        j['excerpt']         as String?,
      coverImageUrl:  j['cover_image_url'] as String?,
      tags:           List<String>.from(j['tags'] as List? ?? []),
      readingMinutes: j['reading_minutes'] as int? ?? 1,
      isFeatured:     j['is_featured']     as bool? ?? false,
      viewCount:      j['view_count']      as int? ?? 0,
      likeCount:      j['like_count']      as int? ?? 0,
      commentCount:   j['comment_count']   as int? ?? 0,
      publishedAt:    j['published_at'] != null
          ? DateTime.tryParse(j['published_at'] as String)
          : null,
      author: authorJson == null
          ? null
          : ArticleAuthor(
              id:        authorJson['id']         as String,
              fullName:  authorJson['full_name']  as String,
              avatarUrl: authorJson['avatar_url'] as String?,
            ),
    );
  }
}

// ── Event ─────────────────────────────────────────────────────────────────────
class EventSummaryModel extends EventSummary {
  const EventSummaryModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.type,
    super.bannerUrl,
    super.venue,
    required super.startsAt,
    super.endsAt,
    required super.registrationOpen,
    required super.registeredCount,
    super.capacity,
  });

  factory EventSummaryModel.fromJson(Map<String, dynamic> j) {
    return EventSummaryModel(
      id:                j['id']                as String,
      title:             j['title']             as String,
      slug:              j['slug']              as String,
      type:              j['type']              as String,
      bannerUrl:         j['banner_url']        as String?,
      venue:             j['venue']             as String?,
      // tryParse + fallback: DateTime.parse throws FormatException on bad input
      // and TypeError on null; either would crash the entire Future.wait batch.
      startsAt: DateTime.tryParse(j['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt:            j['ends_at'] != null
          ? DateTime.tryParse(j['ends_at'] as String)
          : null,
      registrationOpen:  j['registration_open']  as bool? ?? false,
      registeredCount:   j['registered_count']   as int? ?? 0,
      capacity:          j['capacity']            as int?,
    );
  }
}

// ── Opportunity ───────────────────────────────────────────────────────────────
class OpportunitySummaryModel extends OpportunitySummary {
  const OpportunitySummaryModel({
    required super.id,
    required super.type,
    required super.company,
    required super.role,
    super.location,
    required super.isRemote,
    super.compensation,
    super.companyLogoUrl,
    super.applyUrl,
    super.deadline,
    required super.isActive,
  });

  factory OpportunitySummaryModel.fromJson(Map<String, dynamic> j) {
    return OpportunitySummaryModel(
      id:             j['id']               as String,
      type:           j['type']             as String,
      company:        j['company']          as String,
      role:           j['role']             as String,
      location:       j['location']         as String?,
      isRemote:       j['is_remote']        as bool? ?? false,
      compensation:   j['compensation']     as String?,
      companyLogoUrl: j['company_logo_url'] as String?,
      applyUrl:       j['apply_url']        as String?,
      deadline:       j['deadline'] != null
          ? DateTime.tryParse(j['deadline'] as String)
          : null,
      isActive:       j['is_active']        as bool? ?? true,
    );
  }
}

// ── Publication ───────────────────────────────────────────────────────────────
class PublicationSummaryModel extends PublicationSummary {
  const PublicationSummaryModel({
    required super.id,
    required super.title,
    required super.type,
    required super.academicYear,
    super.coverImageUrl,
    required super.pdfUrl,
    required super.downloadCount,
    super.publishedAt,
  });

  factory PublicationSummaryModel.fromJson(Map<String, dynamic> j) {
    return PublicationSummaryModel(
      id:             j['id']               as String,
      title:          j['title']            as String,
      type:           j['type']             as String,
      academicYear:   j['academic_year']    as String,
      coverImageUrl:  j['cover_image_url']  as String?,
      pdfUrl:         j['pdf_url']          as String,
      downloadCount:  j['download_count']   as int? ?? 0,
      publishedAt:    j['published_at'] != null
          ? DateTime.tryParse(j['published_at'] as String)
          : null,
    );
  }
}
