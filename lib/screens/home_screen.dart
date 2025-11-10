// screens/home_screen.dart

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart'; // IMPORTED for Cupertino icons
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

  // --- UPDATED: Using modern Cupertino icons ---
  final iconList = <IconData>[
    CupertinoIcons.home,
    CupertinoIcons.square_list,
    CupertinoIcons.clock,
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
      // --- UPDATED: Smoother, more modern animation curve and duration ---
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
                // --- FIX: Pop dialog FIRST ---
                Navigator.of(dialogContext).pop();
                // --- THEN call logout ---
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
        // --- UPDATED: AnimatedSwitcher for a cool title transition ---
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -0.5),
                  end: const Offset(0.0, 0.0),
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            getTitle(_selectedIndex),
            key: ValueKey<int>(_selectedIndex), // Ensures the animation triggers
            style: TextStyle(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.onBackground 
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout, // Sticking with Material icon for logout
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.onBackground.withOpacity(0.7)
                  : Colors.grey[700],
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
        backgroundColor: theme.cardTheme.color,
        // --- UPDATED: Added splash color and modern shadow ---
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        splashSpeedInMilliseconds: 300,
        shadow: BoxShadow(
          color: theme.shadowColor.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, -5), // Softer shadow coming from the top
        ),
      ),
    );
  }
}