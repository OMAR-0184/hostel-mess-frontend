// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

// Import the screens (we will use the visually updated versions)
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

  // We use the new, beautifully designed screens here
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),      // The new dashboard with greeting and notices
    const BookingScreen(),  // The new booking screen with gradient cards
    MyBookingsScreen(),
    NoticeScreen(),
    ProfileScreen(),
  ];

  // Your original, simple, and effective navigation logic is preserved
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String getTitle(int index) {
      switch (index) {
        case 0: return 'Dashboard';
        case 1: return 'Book a Meal';
        case 2: return 'My Bookings';
        case 3: return 'Notices';
        case 4: return 'Profile';
        default: return 'Hostel Mess';
      }
    }

    return Scaffold(
      // Use the theme's background color for a consistent look
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        // A modern, clean AppBar style
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          getTitle(_selectedIndex),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.primary),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      // The body transitions instantly on tap, just like your original app
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Here is the styled BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Book Meal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        // Style the navigation bar
        backgroundColor: Colors.white,
        selectedItemColor: theme.colorScheme.primary, // Your theme's primary color
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        // These are important for the styling to work correctly
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 5,
      ),
    );
  }
}