// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/my_bookings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // --- 1. State variable to track visible items ---
  int _visibleCount = 5;
  static const int _incrementCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyBookingsProvider>(context, listen: false)
          .fetchBookingHistory();
    });
  }

  void _loadMore() {
    setState(() {
      _visibleCount += _incrementCount;
    });
  }

  // --- 3. NEW HEADER WIDGET ---
  Widget _buildHeader(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.blueGrey.shade800, Colors.black.withOpacity(0.5)]
              : [Colors.white, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Conditional black border for light mode
          color: isDarkMode ? Colors.grey.shade700 : Colors.black,
          width: isDarkMode ? 1.0 : 2.0, // Thicker border in light mode
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded,
              size: 40, color: theme.colorScheme.primary),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Bookings",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Your complete meal history",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- THIS IS THE FIX ---
      // Wrap the body in a SafeArea to prevent overlap
      // with the system status bar (top) and navigation bar (bottom).
      body: SafeArea(
        top: true,
        bottom: true,
        child: Consumer<MyBookingsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return _buildInfoMessage(
                theme,
                message: provider.errorMessage!,
                lottieAsset: 'assets/not_found.json',
              );
            }
            if (provider.bookingHistory.isEmpty) {
              // --- MODIFIED: Added header to empty state as well ---
              return Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: _buildInfoMessage(
                      theme,
                      message: 'No meals cooked up yet 🍽️',
                      subMessage: 'Book a meal to see it here!',
                      lottieAsset: 'assets/no-food.json',
                    ),
                  ),
                ],
              );
            }

            final sortedHistory = List.of(provider.bookingHistory);
            sortedHistory
                .sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

            // --- 2. Calculate display counts ---
            final int totalItems = sortedHistory.length;
            final int currentDisplayCount =
                (_visibleCount < totalItems) ? _visibleCount : totalItems;
            final bool hasMore = _visibleCount < totalItems;

            // --- MODIFIED: Wrapped in Column and added Header ---
            return Column(
              children: [
                _buildHeader(theme), // ADDED HEADER
                Expanded(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 4.0), // Adjusted padding
                      itemCount: currentDisplayCount + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // If we are at the last index and hasMore is true, show the button
                        if (hasMore && index == currentDisplayCount) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: FadeInAnimation(
                              child: Padding(
                                // --- MODIFICATION: Added bottom padding for the button ---
                                padding: const EdgeInsets.only(
                                    top: 16.0, bottom: 16.0),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: _loadMore,
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: theme.colorScheme.primary),
                                    label: Text(
                                      "See More",
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      backgroundColor: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // Otherwise, render the booking card
                        final booking = sortedHistory[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: TimelineBookingCard(
                                booking: booking,
                                isLast: index == currentDisplayCount - 1 &&
                                    !hasMore,
                                theme: theme,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoMessage(ThemeData theme,
      {required String message,
      String? subMessage,
      required String lottieAsset}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(lottieAsset,
              width: 200, height: 200, fit: BoxFit.contain),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class TimelineBookingCard extends StatelessWidget {
  final BookingHistoryItem booking;
  final bool isLast;
  final ThemeData theme;

  const TimelineBookingCard({
    Key? key,
    required this.booking,
    required this.isLast,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(booking.bookingDate, DateTime.now());
    final isDarkMode = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineMarker(context, isToday),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          const Color(0xFF2C3E50).withOpacity(0.8),
                          const Color(0xFF000000).withOpacity(0.6),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF5F7FA),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isToday
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : (isDarkMode ? Colors.transparent : Colors.black),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isToday
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE')
                                      .format(booking.bookingDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('d MMMM')
                                      .format(booking.bookingDate),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Today",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Meals
                        _buildMealSection(
                          title: 'Lunch',
                          items: booking.lunchPick,
                          gradientColors: isDarkMode
                              ? [
                                  const Color(0xFFB96C38),
                                  const Color(0xFF7E4118)
                                ]
                              : [
                                  const Color(0xFFFFF3E0),
                                  const Color(0xFFFFE0B2)
                                ],
                          iconColor: Colors.orange,
                          icon: Icons.wb_sunny_rounded,
                          textColor: isDarkMode
                              ? Colors.orange.shade100
                              : Colors.orange.shade900,
                        ),
                        const SizedBox(height: 8),
                        _buildMealSection(
                          title: 'Dinner',
                          items: booking.dinnerPick,
                          gradientColors: isDarkMode
                              ? [
                                  const Color(0xFF4A3880),
                                  const Color(0xFF291E4E)
                                ]
                              : [
                                  const Color(0xFFEDE7F6),
                                  const Color(0xFFD1C4E9)
                                ],
                          iconColor: Colors.deepPurple,
                          icon: Icons.nights_stay_rounded,
                          textColor: isDarkMode
                              ? Colors.deepPurple.shade100
                              : Colors.deepPurple.shade900,
                        ),
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

  Widget _buildTimelineMarker(BuildContext context, bool isToday) {
    final color = isToday ? theme.colorScheme.primary : Colors.grey.shade300;

    return Column(
      children: [
        if (isToday)
          _PulsingMarker(color: color)
        else
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
        Expanded(
          child: Container(
            width: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection({
    required String title,
    required List<String>? items,
    required List<Color> gradientColors,
    required Color iconColor,
    required IconData icon,
    required Color textColor,
  }) {
    final hasItems = items != null && items.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasItems)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items!.map((item) => _buildMealChip(item)).toList(),
            )
          else
            Text(
              "Not Booked",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: textColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealChip(String label) {
    String iconText = '🍴';
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('chicken'))
      iconText = '🍗';
    else if (lowerLabel.contains('paneer'))
      iconText = '🧀';
    else if (lowerLabel.contains('egg'))
      iconText = '🥚';
    else if (lowerLabel.contains('rice'))
      iconText = '🍚';
    else if (lowerLabel.contains('dal') || lowerLabel.contains('daal'))
      iconText = '🥣';
    else if (lowerLabel.contains('roti') ||
        lowerLabel.contains('bread') ||
        lowerLabel.contains('naan'))
      iconText = '🫓';
    else if (lowerLabel.contains('burger'))
      iconText = '🍔';
    else if (lowerLabel.contains('fish'))
      iconText = '🐟';
    else if (lowerLabel.contains('salad')) iconText = '🥗';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(iconText, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final Color color;
  const _PulsingMarker({Key? key, required this.color}) : super(key: key);

  @override
  _PulsingMarkerState createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 16 * _animation.value,
          height: 16 * _animation.value,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
