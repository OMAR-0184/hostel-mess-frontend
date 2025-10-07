// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'provider/admin_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/booking_provider.dart';
import 'provider/menu_provider.dart';
import 'provider/my_bookings_provider.dart';
import 'provider/notice_provider.dart';
import 'provider/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// A helper class to hold theme data
class AppThemes {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3D5AFE),
      primary: const Color(0xFF3D5AFE),
      secondary: const Color(0xFF18FFFF),
      background: const Color(0xFFF7F8FC),
      brightness: Brightness.light,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1F2937), // Dark Slate Blue
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF38BDF8), // Sky Blue Seed
      primary: const Color(0xFF38BDF8),   // Sky Blue Primary
      secondary: const Color(0xFFF472B6), // Pink Secondary
      background: const Color(0xFF1F2937),
      surface: const Color(0xFF374151), // Lighter Slate Blue for cards
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: const Color(0xFFE5E7EB), // Light Grey for text
      onSurface: const Color(0xFFE5E7EB),
      brightness: Brightness.dark,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF374151),
      elevation: 4,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFE5E7EB),
      displayColor: const Color(0xFFE5E7EB),
    ),
    useMaterial3: true,
  );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => MyBookingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Hostel Mess',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return Scaffold(body: Center(child: Lottie.asset('assets/loader.json')));
                }
                return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}