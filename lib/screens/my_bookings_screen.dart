// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/my_bookings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyBookingsProvider>(context, listen: false).fetchBookingHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<MyBookingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return _buildInfoMessage(
              icon: Icons.error_outline,
              message: provider.errorMessage!,
            );
          }
          if (provider.bookingHistory.isEmpty) {
            return _buildInfoMessage(
              icon: Icons.calendar_today_outlined,
              message: 'You have no booking history yet.',
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: provider.bookingHistory.length,
              itemBuilder: (context, index) {
                final booking = provider.bookingHistory[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 400),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildTimelineCard(theme, booking, index),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// The main card widget, designed as a timeline event.
  Widget _buildTimelineCard(ThemeData theme, BookingHistoryItem booking, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The timeline's visual elements (line and dot)
          _buildTimelineMarker(theme, index),
          const SizedBox(width: 16),
          // The card with the booking details
          Expanded(
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(booking.bookingDate.toLocal()),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _buildMealDetail(
                      theme,
                      icon: Icons.wb_sunny_outlined,
                      title: 'Lunch',
                      items: booking.lunchPick,
                    ),
                    const SizedBox(height: 16),
                    _buildMealDetail(
                      theme,
                      icon: Icons.nightlight_round_outlined,
                      title: 'Dinner',
                      items: booking.dinnerPick,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates the dot and vertical line for the timeline effect.
  Widget _buildTimelineMarker(ThemeData theme, int index) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: CircleAvatar(
            radius: 8,
            backgroundColor: theme.colorScheme.primary,
          ),
        ),
        Container(
          width: 2,
          height: 150, // Adjust height to control spacing
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ],
    );
  }

  /// Displays the details for a single meal (Lunch or Dinner).
  Widget _buildMealDetail(ThemeData theme, {required IconData icon, required String title, List<String>? items}) {
    bool isBooked = items != null && items.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (isBooked)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items!.map((item) => Chip(
              label: Text(item),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              side: BorderSide.none,
            )).toList(),
          )
        else
          Text(
            'Not Booked',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
          ),
      ],
    );
  }

  /// A centered widget to display when the list is empty or there's an error.
  Widget _buildInfoMessage({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}