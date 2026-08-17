import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'injection.dart';
import 'presentation/blocs/task_bloc.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/dashboard_kanban_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://qffxmdfatpvfjaoqoqod.supabase.co',
    publishableKey: 'sb_publishable_7vtyaW7IciX5qB3m-9bw8g_ZOCWMsRd',
  );

  await initInjection();

  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>()..add(CheckAuthStatusRequested()),
      child: MaterialApp(
        title: 'TaskFlow Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => BlocProvider(
                create: (_) => sl<TaskBloc>(),
                child: const DashboardKanbanScreen(),
              ),
        },
      ),
    );
  }
}
