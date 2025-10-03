// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for better fonts
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'provider/admin_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/booking_provider.dart';
import 'provider/menu_provider.dart';
import 'provider/my_bookings_provider.dart';
import 'provider/notice_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Hostel Mess',

        // =================== THE UPDATED COLOR SCHEME ===================
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3D5AFE),   // A vibrant indigo
            primary: const Color(0xFF3D5AFE),     // Main interactive color
            secondary: const Color(0xFF18FFFF),   // Bright aqua for accents
            background: const Color(0xFFF7F8FC), // A very light, clean background
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        // =================================================================

        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return Scaffold(body: Center(child: Lottie.asset('assets/loader.json')));
            }
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}