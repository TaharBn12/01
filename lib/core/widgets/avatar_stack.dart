import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/app_user.dart';
import '../../features/rooms/data/rooms_repository.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// كومة وجوه متداخلة لحضور الغرفة (تُقرأ لحظيًّا من قاعدة البيانات)
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.roomId,
    required this.total,
    this.size = 24,
    this.max = 3,
  });

  final String roomId;
  final int total;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RoomsRepository>();
    return StreamBuilder<List<AppUser>>(
      stream: repo.watchAttendees(roomId, limit: max),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AppUser>[];
        if (users.isEmpty && total <= 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _circle(
                context,
                child: Icon(Icons.person, size: size * 0.62, color: context.text3),
              ),
            ],
          );
        }

        final overlap = size * 0.62;
        final extra = total > users.length ? total - users.length : 0;
        final itemCount = users.length + (extra > 0 ? 1 : 0);

        return SizedBox(
          height: size,
          width: size + overlap * (itemCount - 1),
          child: Stack(
            children: [
              for (var i = 0; i < users.length; i++)
                PositionedDirectional(
                  top: 0,
                  start: i * overlap,
                  child: _circle(
                    context,
                    child: UserAvatar(
                      name: users[i].name,
                      photoUrl: users[i].photoUrl,
                      radius: size / 2 - 1.4,
                    ),
                  ),
                ),
              if (extra > 0)
                PositionedDirectional(
                  top: 0,
                  start: users.length * overlap,
                  child: _circle(
                    context,
                    child: Container(
                      width: size - 2.8,
                      height: size - 2.8,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.variant,
                      ),
                      child: Text(
                        '+$extra',
                        style: TextStyle(
                          fontSize: size * 0.38,
                          fontWeight: FontWeight.w800,
                          color: context.text2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _circle(BuildContext context, {required Widget child}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.cardColor,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
