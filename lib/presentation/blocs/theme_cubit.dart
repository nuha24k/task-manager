import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

class AppTheme {
  static TextTheme _textTheme(BuildContext context, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    return GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
  }

  // Global Light Theme configuration
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // Sets the overall background of your screens to white as well
      scaffoldBackgroundColor: Colors.white,
      textTheme: _textTheme(context, Brightness.light),

      // Fixed Light AppBar configuration
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Forces text and icons to be pure Black
        elevation: 0,
        centerTitle: true,
        // Configures the status bar icons (battery, wifi, time) to be dark so they don't disappear on white
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android: Dark icons
          statusBarBrightness: Brightness.light, // iOS: Dark icons
        ),
      ),
    );
  }

  // Global Dark Theme configuration
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(
        0xFF121212,
      ), // Standard dark background
      textTheme: _textTheme(context, Brightness.dark),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.orangeAccent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Android: Light icons
          statusBarBrightness: Brightness.dark, // iOS: Light icons
        ),
      ),
    );
  }
}
