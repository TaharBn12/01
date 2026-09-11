import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/video_utils.dart';
import '../../../../core/widgets/avatar_stack.dart';
import '../../data/room_model.dart';

/// بطاقة غرفة أفقية:
/// المعاينة على اليمين (اتجاه البدء في RTL) والمعلومات على اليسار،
/// مع عنوان الفيديو وكومة وجوه الحضور.
class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});

  final RoomModel room;
  final VoidCallback onTap;

  IconData get _sourceIcon => switch (room.source) {
        VideoSource.youtube => Icons.smart_display_rounded,
        VideoSource.directVideo => Icons.movie_rounded,
        VideoSource.webPage => Icons.language_rounded,
        VideoSource.unknown => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 760),
        child: Material(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
            child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.line),
              ),
              padding: const EdgeInsets.all(9),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== المعاينة (أوّل عنصر في الصف = يمين الشاشة) =====
                    _Preview(
                      room: room,
                      icon: _sourceIcon,
                    ),
                    const SizedBox(width: 12),
                    // ===== المعلومات =====
                    Expanded(child: _Info(room: room)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.room, required this.icon});

  final RoomModel room;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 104,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: room.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: room.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(color: context.variant),
                    errorWidget: (_, _, _) => _placeholder(context),
                  )
                : _placeholder(context),
          ),
          // طبقة تغميق خفيفة لوضوح الشارات
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
          ),
          if (room.isLive)
            PositionedDirectional(
              top: 7,
              end: 7,
              child: _LiveBadge(count: room.participantCount),
            ),
          PositionedDirectional(
            bottom: 7,
            start: 7,
            child: _SourceTag(icon: icon, label: room.source.label),
          ),
          Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF141416),
      child: Icon(icon, size: 38, color: Colors.white.withValues(alpha: 0.55)),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    final hasVideoTitle = room.videoTitle != null &&
        room.videoTitle!.trim().isNotEmpty &&
        room.videoTitle!.trim() != room.name.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: context.text1,
            ),
          ),
          if (hasVideoTitle) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.smart_display_outlined,
                    size: 13, color: context.text3),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    room.videoTitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.text3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          Row(
            children: [
              AvatarStack(
                roomId: room.id,
                total: room.participantCount,
                size: 24,
              ),
              const SizedBox(width: 7),
              Text(
                room.participantCount == 0
                    ? 'لا مشاهدين'
                    : room.participantCount == 1
                        ? 'مشاهد واحد'
                        : '${room.participantCount} مشاهد',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.text2,
                ),
              ),
              const Spacer(),
              if (room.createdAt != null)
                Text(
                  Formatters.timeAgo(room.createdAt),
                  style: TextStyle(fontSize: 11, color: context.text3),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 13, color: context.text3),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.hostName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.text3,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: context.line),
                ),
                child: Text(
                  room.id,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: context.text2,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 4),
          const Text(
            'مباشر',
            style: TextStyle(
              color: Colors.black,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      ),
    );
  }
}
