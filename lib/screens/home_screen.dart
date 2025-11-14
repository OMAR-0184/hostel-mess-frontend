
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
                Navigator.of(dialogContext).pop();
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
    final isDarkMode = theme.brightness == Brightness.dark;
    
    String getTitle(int index) {
      switch (index) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Book a Meal';
        case 2:
          return 'Notices';
        case 3:
          return 'Profile';
        default:
          return 'Hostel Mess';
      }
    }

    // Index 0 is Dashboard, Index 3 is Profile
    final bool hideAppBar = _selectedIndex == 0 || _selectedIndex == 3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // This allows the PageView to slide under the nav bar
      extendBody: true,
      appBar: hideAppBar 
          ? null 
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true, 
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: const Offset(0.0, 0.0),
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  getTitle(_selectedIndex).toUpperCase(),
                  key: ValueKey<int>(_selectedIndex),
                  style: TextStyle(
                    color: theme.colorScheme.primary, 
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.2, 
                    height: 1.0,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: theme.iconTheme.color?.withOpacity(0.7),
                  ),
                  tooltip: 'Logout',
                  onPressed: () {
                    _showLogoutConfirmationDialog(context);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
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