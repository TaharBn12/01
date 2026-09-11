import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/data/app_user.dart';
import '../../data/message_model.dart';
import '../../data/room_model.dart';
import '../../data/rooms_repository.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.room});

  final RoomModel room;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late final Stream<List<MessageModel>> _messages = context
      .read<RoomsRepository>()
      .watchMessages(widget.room.id);

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final user = AppUser.fromFirebase(firebaseUser);
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      await context.read<RoomsRepository>().sendMessage(
            roomId: widget.room.id,
            user: user,
            text: text,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الرسالة')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const AppLoader(label: 'تحميل الرسائل...');
              }
              if (snapshot.hasError) {
                return ErrorView(
                  error: snapshot.error!,
                  onRetry: () => setState(() {}),
                );
              }
              final messages = snapshot.data ?? const [];
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'لا رسائل بعد',
                  message: 'كن أول من يتفاعل مع الحضور! 👋',
                );
              }
              // الرسائل تصل من Realtime Database مرتبة من الأحدث للأقدم،
              // وقائمة العرض معكوسة ليظهر الأحدث في الأسفل.
              return ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final message = messages[i];
                  final mine = message.uid == myUid;
                  return _MessageBubble(message: message, mine: mine);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: context.mono,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded,
                          color: context.onMono, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        // في الواجهة العربية: رسائلي على اليسار، ورسائل الآخرين على اليمين
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            UserAvatar(
              name: message.senderName,
              photoUrl: message.senderPhotoUrl,
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, right: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.text2,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: mine ? context.mono : context.variant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 4 : 16),
                      bottomRight: Radius.circular(mine ? 16 : 4),
                    ),
                    border: mine
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: mine ? context.onMono : context.text1,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Formatters.timeOfDay(
                          message.createdAt ?? DateTime.now(),
                        ),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: mine
                              ? context.onMono.withValues(alpha: 0.65)
                              : context.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
