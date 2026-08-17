import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/task.dart';
import '../../injection.dart';
import '../blocs/invitation_bloc.dart';
import '../theme/app_colors.dart';

class TaskShareModal extends StatelessWidget {
  final Task task;

  const TaskShareModal({super.key, required this.task});

  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider<InvitationBloc>(
            create: (_) => sl<InvitationBloc>()
              ..add(CreateInvitationRequested(taskId: task.id)),
          ),
        ],
        child: TaskShareModal(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryCard.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.darkText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share & Invite',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      'Invite people to collaborate on "${task.title}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.subText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // BLoC State Handler for Link Share
          BlocConsumer<InvitationBloc, InvitationState>(
            listener: (context, state) {
              if (state is InvitationErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is InvitationLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.darkText,
                    ),
                  ),
                );
              }

              if (state is InvitationCreatedState) {
                return _buildShareLinkContent(
                  context,
                  url: state.shareableUrl,
                  invitationId: state.invitation.id,
                );
              }

              if (state is InvitationRevokedState) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.link_off_rounded, color: Colors.amber, size: 28),
                      const SizedBox(height: 8),
                      const Text(
                        'Link Sharing Disabled',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Previous invitation links have been deactivated.',
                        style: TextStyle(fontSize: 12, color: AppColors.subText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<InvitationBloc>().add(
                                CreateInvitationRequested(taskId: task.id),
                              );
                        },
                        icon: const Icon(Icons.add_link_rounded, size: 16, color: Colors.white),
                        label: const Text('Generate New Link', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.read<InvitationBloc>().add(
                          CreateInvitationRequested(taskId: task.id),
                        );
                  },
                  icon: const Icon(Icons.link_rounded, color: Colors.white),
                  label: const Text('Create Invitation Link', style: TextStyle(color: Colors.white)),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          // Assignees / Collaborators Section
          const Text(
            'Task Members',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          _buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildShareLinkContent(
    BuildContext context, {
    required String url,
    required String invitationId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.public_rounded, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Anyone with the link can join',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Can Edit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Link Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.subText, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkText,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Copy Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Invitation link copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: Colors.black87,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                label: const Text(
                  'Copy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action Buttons: Share Native & Revoke Link
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Share.share(
                    'Join task "${task.title}" on TaskFlow: $url',
                    subject: 'Task Invitation: ${task.title}',
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 16, color: AppColors.darkText),
                label: const Text(
                  'Share via App',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Disable Link',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                context.read<InvitationBloc>().add(
                      RevokeInvitationRequested(invitationId: invitationId),
                    );
              },
              icon: const Icon(Icons.link_off_rounded, color: Colors.red, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    final assignees = task.assigneeIds;
    if (assignees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'No members assigned yet. Share the link above to invite!',
            style: TextStyle(fontSize: 12, color: AppColors.subText),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: assignees.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (ctx, index) {
          final userId = assignees[index];
          final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryCard,
              child: Text(
                shortId.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
            title: Text(
              'User ($shortId...)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Member',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
