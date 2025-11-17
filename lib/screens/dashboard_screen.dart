// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/auth_provider.dart';
import '../provider/booking_provider.dart';
import '../provider/notice_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Import NoticeScreen for the "View All" navigation
import 'notice_screen.dart';
import 'feedback_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool _showAllNotices = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    }
    return 'Good Evening';
  }

  Future<void> _refreshData() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final noticeProvider = Provider.of<NoticeProvider>(context, listen: false);

    await Future.wait([
      bookingProvider.fetchTodaysBooking(forceRefresh: true),
      noticeProvider.fetchNotices(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final User? user = Provider.of<AuthProvider>(context).user;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND GRADIENT MESH
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [const Color(0xFF020617), const Color(0xFF0F172A)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
              ),
            ),
          ),
          // ACCENT ORB
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary
                      .withOpacity(isDarkMode ? 0.1 : 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withOpacity(isDarkMode ? 0.1 : 0.05),
                      blurRadius: 100,
                      spreadRadius: 50,
                    )
                  ]),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: theme.colorScheme.primary,
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildHeader(user, theme),
                        const SizedBox(height: 32),
                        _buildTodaysBookingSection(theme),
                        const SizedBox(height: 32),
                        _buildLatestNoticesSection(context, theme),
                        const SizedBox(height: 32),
                        _buildFooterSection(context, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "MessBook",
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_getGreeting()}, ${user?.name.split(' ')[0] ?? 'User'}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF007BFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user?.name.isNotEmpty ?? false
                  ? user!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysBookingSection(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    final lunchGradient = [
      const Color(0xFFFF9966),
      const Color(0xFFFF5E62),
    ];
    final dinnerGradient = [
      const Color(0xFF4568DC),
      const Color(0xFFB06AB3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_menu_rounded,
                color: theme.textTheme.titleLarge?.color, size: 28),
            const SizedBox(width: 10),
            Text(
              "Your Meal",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Consumer<BookingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingTodaysBooking &&
                provider.todaysBooking == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final lunchItems =
                provider.todaysBooking?['lunch_pick'] as List<dynamic>? ?? [];
            final dinnerItems =
                provider.todaysBooking?['dinner_pick'] as List<dynamic>? ?? [];

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildModernMealCard(
                      theme: theme,
                      title: 'Lunch',
                      icon: Icons.wb_sunny_rounded,
                      gradientColors: lunchGradient,
                      shadowColor: Colors.orange.withOpacity(0.4),
                      bookedItems:
                          lunchItems.map((item) => item.toString()).toList(),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernMealCard(
                      theme: theme,
                      title: 'Dinner',
                      icon: Icons.nights_stay_rounded,
                      gradientColors: dinnerGradient,
                      shadowColor: Colors.blue.withOpacity(0.4),
                      bookedItems:
                          dinnerItems.map((item) => item.toString()).toList(),
                      isDarkMode: isDarkMode,
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

  Widget _buildModernMealCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required List<String> bookedItems,
    required bool isDarkMode,
  }) {
    final bool isBooked = bookedItems.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isBooked
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isBooked ? null : theme.cardTheme.color,
        boxShadow: isBooked
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
        border: isBooked
            ? null
            : Border.all(
                color: isDarkMode ? Colors.transparent : Colors.black,
                width: 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.white.withOpacity(0.2)
                          : theme.scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isBooked
                          ? Colors.white
                          : (title == 'Lunch' ? Colors.orange : Colors.indigo),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBooked
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBooked ? '${bookedItems.length} items' : 'Not Booked',
                    style: TextStyle(
                      color: isBooked ? Colors.white70 : Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isBooked)
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: bookedItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      "Empty",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestNoticesSection(BuildContext context, ThemeData theme) {
    final List<Color> lightCardColors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFF3E5F5),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
    ];

    final List<Color> darkCardColors = [
      const Color(0xFF1565C0).withOpacity(0.3),
      const Color(0xFF6A1B9A).withOpacity(0.3),
      const Color(0xFF2E7D32).withOpacity(0.3),
      const Color(0xFFEF6C00).withOpacity(0.3),
    ];

    final List<Color> accentColors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
    ];

    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_rounded,
                    color: theme.textTheme.titleLarge?.color, size: 28),
                const SizedBox(width: 10),
                Text(
                  "Latest Notices",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NoticeScreen()));
              },
              child: Text("View All",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Consumer<NoticeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.notices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.notices.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Text(
                    "No new notices available.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            final int countToShow = _showAllNotices ? 3 : 1;
            final noticesToShow = provider.notices.take(countToShow).toList();
            final bool canExpand = provider.notices.length > 1;

            return Column(
              children: [
                ...noticesToShow.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notice = entry.value;
                  final colorIndex = index % lightCardColors.length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DashboardNoticeCard(
                      notice: notice,
                      backgroundColor: isDarkMode
                          ? darkCardColors[colorIndex]
                          : lightCardColors[colorIndex],
                      accentColor: accentColors[colorIndex],
                    ),
                  );
                }).toList(),
                if (canExpand)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllNotices = !_showAllNotices;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showAllNotices ? "Show Less" : "Show More Notices",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _showAllNotices
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.primary,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooterSection(BuildContext context, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isDarkMode ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.teal.withOpacity(0.4)
                  : Colors.teal.shade100,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tips_and_updates_outlined,
                    color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Health Tip",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stay hydrated! Drink at least 8 glasses of water daily.",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FeedbackScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.purple.shade900, Colors.deepPurple.shade900]
                    : [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Have a suggestion?",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rate today's meal & help us improve.",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardNoticeCard extends StatefulWidget {
  final Notice notice;
  final Color backgroundColor;
  final Color accentColor;

  const DashboardNoticeCard({
    super.key,
    required this.notice,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  State<DashboardNoticeCard> createState() => _DashboardNoticeCardState();
}

// --- FIX: Added 'extends State<DashboardNoticeCard>' ---
class _DashboardNoticeCardState extends State<DashboardNoticeCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                isDarkMode ? widget.accentColor.withOpacity(0.2) : Colors.black,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 100,
                  color: widget.accentColor.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.priority_high_rounded,
                            size: 16,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.notice.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: widget.accentColor,
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          widget.notice.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(widget.notice.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: widget.accentColor.withOpacity(0.2)),
                            const SizedBox(height: 8),
                            Text(
                              widget.notice.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
