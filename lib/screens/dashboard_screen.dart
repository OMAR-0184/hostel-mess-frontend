// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/auth_provider.dart';
import '../provider/booking_provider.dart';
import '../provider/notice_provider.dart';
import 'package:intl/intl.dart';

// Import screens for navigation
import 'booking_screen.dart';
import 'menu_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  
  // This is required to keep the state alive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchTodaysBooking();
      Provider.of<NoticeProvider>(context, listen: false).fetchNotices();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _refreshData() async {
    await Future.wait([
      Provider.of<BookingProvider>(context, listen: false)
          .fetchTodaysBooking(forceRefresh: true),
      Provider.of<NoticeProvider>(context, listen: false)
          .fetchNotices(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is required for AutomaticKeepAliveClientMixin
    final User? user = Provider.of<AuthProvider>(context).user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(user, theme),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildTodaysBookingSection(theme),
                const SizedBox(height: 24),
                _buildLatestNoticesSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. A more personal and dynamic greeting section
  Widget _buildGreetingSection(User? user, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            user?.name.isNotEmpty ?? false ? user!.name[0].toUpperCase() : 'U',
            style: TextStyle(fontSize: 24, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            Text(
              user?.name ?? 'User',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. Fills screen space and provides useful shortcuts
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(context, icon: Icons.restaurant_menu, label: 'Book Meal', screen: const BookingScreen()),
        _buildActionItem(context, icon: Icons.calendar_today, label: 'View Menu', screen: const MenuScreen()),
        _buildActionItem(context, icon: Icons.history, label: 'My Bookings', screen: MyBookingsScreen()),
        _buildActionItem(context, icon: Icons.person_outline, label: 'Profile', screen: const ProfileScreen()),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required Widget screen}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// 3. The "beautiful" meal status section
  Widget _buildTodaysBookingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Meals", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Consumer<BookingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingTodaysBooking && provider.todaysBooking == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final lunchItems = provider.todaysBooking?['lunch_pick'] as List<dynamic>? ?? [];
            final dinnerItems = provider.todaysBooking?['dinner_pick'] as List<dynamic>? ?? [];

            // FIX: Wrapped the Row with IntrinsicHeight to synchronize card heights
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMealCard(
                      theme: theme,
                      title: 'Lunch',
                      icon: Icons.wb_sunny_outlined,
                      gradientColors: [Colors.orange.shade300, Colors.orange.shade600],
                      bookedItems: lunchItems.map((item) => item.toString()).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMealCard(
                      theme: theme,
                      title: 'Dinner',
                      icon: Icons.nightlight_round_outlined,
                      gradientColors: [Colors.indigo.shade300, Colors.indigo.shade600],
                      bookedItems: dinnerItems.map((item) => item.toString()).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required List<String> bookedItems,
  }) {
    bool isBooked = bookedItems.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isBooked ? LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isBooked ? null : Colors.white,
        border: isBooked ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: isBooked
            ? [BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isBooked ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: isBooked ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          Text(isBooked ? 'Booked' : 'Not Booked', style: TextStyle(color: isBooked ? Colors.white70 : Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (isBooked)
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: bookedItems.map((item) => Chip(
                label: Text(item, style: const TextStyle(color: Colors.black87)),
                backgroundColor: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              )).toList(),
            )
          else
            const Icon(Icons.fastfood_outlined, color: Colors.grey, size: 28),
        ],
      ),
    );
  }

  /// 4. The "serious and eye-catching" notice section, now showing top 3 notices
  Widget _buildLatestNoticesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Latest Notices", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Consumer<NoticeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.notices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.notices.isEmpty) {
              return const Text("No new notices available.", style: TextStyle(fontSize: 16, color: Colors.grey));
            }
            final latestNotices = provider.notices.take(3).toList();
            return Column(
              children: latestNotices.map((notice) => _buildNoticeCard(theme, notice)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoticeCard(ThemeData theme, Notice notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Posted: ${DateFormat('d MMMM, yyyy').format(notice.createdAt.toLocal())}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      notice.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}