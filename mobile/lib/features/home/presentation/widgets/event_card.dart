import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

// ── Countdown ticker ──────────────────────────────────────────────────────────
class _CountdownText extends StatefulWidget {
  final DateTime target;
  const _CountdownText({required this.target});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.target.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.target.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format() {
    if (_remaining.isNegative) return 'Started';
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 12, color: AppColors.accent),
        const SizedBox(width: 4),
        Text(_format(),
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.accent)),
      ],
    );
  }
}

// ── Single event card ─────────────────────────────────────────────────────────
class EventCard extends StatelessWidget {
  final EventSummary event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final dt = event.startsAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            SizedBox(
              height: 130,
              width: double.infinity,
              child: event.bannerUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.bannerUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _BannerPlaceholder(type: event.type),
                      errorWidget: (_, __, ___) =>
                          _BannerPlaceholder(type: event.type),
                    )
                  : _BannerPlaceholder(type: event.type),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        '${dt.day} ${months[dt.month - 1]} · ${_time(dt)}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      event.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.venue != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.venue!,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (event.isUpcoming)
                          _CountdownText(target: event.startsAt),
                        if (event.registrationOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: AppRadius.full,
                            ),
                            child: Text('Open',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.success)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ── Banner placeholder with event-type icon ───────────────────────────────────
class _BannerPlaceholder extends StatelessWidget {
  final String type;
  const _BannerPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'workshop'         => (Icons.build_circle_outlined, AppColors.accent),
      'guest_lecture'    => (Icons.mic_none_rounded, const Color(0xFF0A84FF)),
      'seminar'          => (Icons.co_present_rounded, const Color(0xFFBF5AF2)),
      'industrial_visit' => (Icons.factory_outlined, const Color(0xFFFF9F0A)),
      'freshers'         => (Icons.celebration_rounded, AppColors.success),
      'farewell'         => (Icons.waving_hand_rounded, const Color(0xFFFF375F)),
      _                  => (Icons.event_rounded, AppColors.accent),
    };
    return Container(
      color: AppColors.surfaceHigh,
      child: Center(child: Icon(icon, size: 42, color: color.withValues(alpha: 0.6))),
    );
  }
}

// ── Horizontal scroll section ─────────────────────────────────────────────────
class EventsSection extends StatelessWidget {
  final List<EventSummary> events;
  final void Function(String slug) onEventTap;

  const EventsSection({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 100,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
          ),
          child: Text('No upcoming events',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );
    }
    return SizedBox(
      height: 302,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => EventCard(
          event: events[i],
          onTap: () => onEventTap(events[i].slug),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class EventsSectionSkeleton extends StatelessWidget {
  const EventsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 302,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceHigh,
          child: Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lg,
            ),
          ),
        ),
      ),
    );
  }
}
