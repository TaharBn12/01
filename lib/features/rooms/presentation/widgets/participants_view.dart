import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/data/app_user.dart';
import '../../data/room_model.dart';
import '../../data/rooms_repository.dart';

class ParticipantsView extends StatefulWidget {
  const ParticipantsView({super.key, required this.room});

  final RoomModel room;

  @override
  State<ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends State<ParticipantsView> {
  late final Stream<List<AppUser>> _stream = context
      .read<RoomsRepository>()
      .watchParticipants(widget.room.id);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppLoader();
        }
        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error!,
            onRetry: () {},
          );
        }
        final users = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(
                Formatters.counter(users.length),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // المضيف دائمًا في الأعلى
            ...users.map((user) {
              final isHost = user.uid == widget.room.hostUid;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHost
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: user.name,
                      photoUrl: user.photoUrl,
                      radius: 20,
                      showLiveRing: isHost,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isHost) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.workspace_premium_rounded,
                                    size: 16, color: AppColors.warning),
                              ],
                            ],
                          ),
                          Text(
                            isHost ? 'مضيف الغرفة' : user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded,
                                size: 12, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'يشاهد',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
