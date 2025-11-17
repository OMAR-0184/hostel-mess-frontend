// lib/screens/home_screen.dart

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'dart:ui'; 

// Import the screens
import 'dashboard_screen.dart';
import 'booking_screen.dart';
import 'notice_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final iconList = <IconData>[
    CupertinoIcons.home,
    CupertinoIcons.square_list,
    CupertinoIcons.bell,
    CupertinoIcons.person,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const BookingScreen(),
    const NoticeScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  // --- REMOVED: _showLogoutConfirmationDialog (already in profile_screen.dart) ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // --- REMOVED: getTitle function ---

    // --- REMOVED: hideAppBar boolean ---

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // This allows the PageView to slide under the nav bar
      extendBody: true,
      
      // --- REMOVED: appBar property ---
      
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: _widgetOptions,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // --- NAVBAR WRAPPED FOR GLASS EFFECT ---
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0), 
          child: AnimatedBottomNavigationBar(
            icons: iconList,
            activeIndex: _selectedIndex,
            gapLocation: GapLocation.none,
            notchSmoothness: NotchSmoothness.verySmoothEdge,
            leftCornerRadius: 32,
            rightCornerRadius: 32,
            onTap: (index) => _onItemTapped(index),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.onSurface.withOpacity(0.6),
            
            backgroundColor: isDarkMode 
                ? Colors.black.withOpacity(0.25) 
                : Colors.white.withOpacity(0.25), 
            splashColor: theme.colorScheme.primary.withOpacity(0.15),
            iconSize: 26, 
            shadow: BoxShadow(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.1), 
              blurRadius: 0,
              spreadRadius: 0.25, 
              offset: const Offset(0, -0.25), 
            ),
          ),
        ),
      ),
    );
  }
}