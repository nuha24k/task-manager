import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection.dart';
import '../blocs/invitation_bloc.dart';
import '../theme/app_colors.dart';

class InvitationPreviewDialog extends StatelessWidget {
  final String token;
  final VoidCallback? onAccepted;

  const InvitationPreviewDialog({
    super.key,
    required this.token,
    this.onAccepted,
  });

  static void show(BuildContext context, String token, {VoidCallback? onAccepted}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider<InvitationBloc>(
        create: (_) => sl<InvitationBloc>()
          ..add(GetInvitationDetailsRequested(token: token)),
        child: InvitationPreviewDialog(
          token: token,
          onAccepted: onAccepted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BlocConsumer<InvitationBloc, InvitationState>(
          listener: (context, state) {
            if (state is InvitationAcceptedState) {
              final result = state.result;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        result.success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(result.message)),
                    ],
                  ),
                  backgroundColor: result.success ? Colors.green.shade700 : Colors.orange.shade800,
                  duration: const Duration(seconds: 3),
                ),
              );

              if (result.success && onAccepted != null) {
                onAccepted!();
              }
            }
          },
          builder: (context, state) {
            if (state is InvitationLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkText),
                    SizedBox(height: 16),
                    Text(
                      'Loading invitation details...',
                      style: TextStyle(fontSize: 13, color: AppColors.subText),
                    ),
                  ],
                ),
              );
            }

            if (state is InvitationErrorState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Invalid Invitation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.subText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }

            if (state is InvitationDetailsLoadedState) {
              final invitation = state.invitation;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 36,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Task Collaboration Invite',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have been invited to join and collaborate on this task as "${invitation.role.toUpperCase()}".',
                    style: const TextStyle(fontSize: 13, color: AppColors.subText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Decline', style: TextStyle(color: AppColors.subText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            context.read<InvitationBloc>().add(
                                  AcceptInvitationRequested(token: token),
                                );
                          },
                          child: const Text(
                            'Accept & Join',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
