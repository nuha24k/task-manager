import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../../injection.dart';
import '../blocs/chat_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';

class TeamChatScreen extends StatelessWidget {
  final Task task;

  const TeamChatScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => sl<ChatBloc>()..add(WatchCommentsRequested(task.id)),
      child: _TeamChatView(task: task),
    );
  }
}

class _TeamChatView extends StatefulWidget {
  final Task task;

  const _TeamChatView({required this.task});

  @override
  State<_TeamChatView> createState() => _TeamChatViewState();
}

class _TeamChatViewState extends State<_TeamChatView> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _sendChatMessage(BuildContext context) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    String userId = 'user_anonymous';
    if (authState is Authenticated) {
      userId = authState.user.id;
    }

    context.read<ChatBloc>().add(
      SendCommentRequested(
        taskId: widget.task.id,
        content: text,
        userId: userId,
      ),
    );

    _chatController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.darkText,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Team Chat',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.subText,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              widget.task.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading chat: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (state is ChatLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: AppColors.subText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No messages yet in ${widget.task.title}.\nStart the conversation below!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.subText),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final authState = context.watch<AuthBloc>().state;
                  final currentUserId = authState is Authenticated
                      ? authState.user.id
                      : null;

                  // Build oldest -> newest with a date separator inserted
                  // before the first message of each calendar day, then
                  // reverse the whole thing so it drops straight into a
                  // reverse:true ListView (newest message at the bottom).
                  final chronological = state.comments;
                  final items = <Widget>[];
                  DateTime? lastDate;
                  for (final comment in chronological) {
                    final day = DateTime(
                      comment.createdAt.year,
                      comment.createdAt.month,
                      comment.createdAt.day,
                    );
                    if (lastDate == null || day != lastDate) {
                      items.add(_buildDateSeparator(day));
                      lastDate = day;
                    }
                    items.add(
                      _buildChatBubble(
                        context,
                        comment,
                        isMe: comment.userId == currentUserId,
                      ),
                    );
                  }
                  final reversedItems = items.reversed.toList();

                  return ListView.builder(
                    controller: _chatScrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: reversedItems.length,
                    itemBuilder: (ctx, index) => reversedItems[index],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendChatMessage(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.darkText,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _sendChatMessage(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _formatDateLabel(day),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.subText,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('EEEE, d MMMM yyyy').format(day);
  }

  Widget _buildChatBubble(
    BuildContext context,
    TaskComment comment, {
    required bool isMe,
  }) {
    final formattedTime = DateFormat('HH:mm').format(comment.createdAt);
    final bubbleColor = isMe ? const Color(0xFF3B82F6) : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.darkText;
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.subText;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe) ...[
                Text(
                  comment.userId.isNotEmpty
                      ? 'User ${comment.userId.length > 6 ? comment.userId.substring(0, 6) : comment.userId}'
                      : 'Unknown user',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                comment.content,
                style: TextStyle(fontSize: 14, color: textColor, height: 1.3),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(fontSize: 10, color: timeColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
