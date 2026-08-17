import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Trigger auth check
    context.read<AuthBloc>().add(CheckAuthStatusRequested());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final nav = Navigator.of(context);
        if (state is Authenticated) {
          Future.delayed(const Duration(milliseconds: 500), () {
            nav.pushReplacementNamed('/dashboard');
          });
        } else if (state is Unauthenticated) {
          Future.delayed(const Duration(milliseconds: 500), () {
            nav.pushReplacementNamed('/login');
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.priorityHigh.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.space_dashboard_rounded,
                      size: 44,
                      color: AppColors.blackButton,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TaskFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Master your projects effortlessly',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.blackButton,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
