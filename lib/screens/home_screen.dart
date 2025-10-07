// screens/home_screen.dart

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

// Import the screens
import 'dashboard_screen.dart';
import 'booking_screen.dart';
import 'my_bookings_screen.dart'; 
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
    Icons.home_outlined,
    Icons.restaurant_menu_outlined,
    Icons.history_outlined, 
    Icons.notifications_outlined,
    Icons.person_outline,
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
    MyBookingsScreen(),
    const NoticeScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String getTitle(int index) {
      switch (index) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Book a Meal';
        case 2:
          return 'My Bookings';
        case 3:
          return 'Notices';
        case 4:
          return 'Profile';
        default:
          return 'Hostel Mess';
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          getTitle(_selectedIndex),
          style: TextStyle(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.onBackground 
                : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.onBackground 
                  : theme.colorScheme.primary,
            ),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => _onItemTapped(index),
        activeColor: theme.colorScheme.primary,
        inactiveColor: theme.colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: theme.cardTheme.color, // Use theme-aware card color
        shadow: BoxShadow(
          color: theme.brightness == Brightness.dark 
              ? Colors.black.withOpacity(0.4) 
              : Colors.black.withOpacity(0.1),
          blurRadius: 10,
        ),
      ),
    );
  }
}