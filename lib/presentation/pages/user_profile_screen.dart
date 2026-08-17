import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String userName = 'Esther Howard';
              String userEmail = 'esther.howard@gmail.com';
              String avatarUrl = 'https://i.pravatar.cc/100?img=33';

              if (state is Authenticated) {
                userName = state.user.name;
                userEmail = state.user.email;
                if (state.user.avatarUrl != null && state.user.avatarUrl!.isNotEmpty) {
                  avatarUrl = state.user.avatarUrl!;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Title Header
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar & Name Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 44,
                                backgroundImage: NetworkImage(avatarUrl),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.blackButton,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.subText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.priorityMedium),
                              SizedBox(width: 6),
                              Text(
                                'Pro Member',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Items Section
                  _buildMenuSection(context),
                  const SizedBox(height: 120),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.chipBackground),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            trailingText: 'On',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.chipBackground),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Security & Password',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.chipBackground),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.chipBackground),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              context.read<AuthBloc>().add(SignOutRequested());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Color titleColor = AppColors.darkText,
    Color iconColor = AppColors.darkText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(trailingText, style: const TextStyle(fontSize: 12, color: AppColors.subText)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.subText),
        ],
      ),
    );
  }
}
