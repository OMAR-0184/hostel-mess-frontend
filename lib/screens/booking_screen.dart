// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
// REMOVED: import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../provider/booking_provider.dart';
import '../provider/menu_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../provider/auth_provider.dart';
import '../provider/my_bookings_provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDate; // MODIFIED: Initialized in initState
  final Map<String, List<String>> _selectedMeals = {'lunch': [], 'dinner': []};
  bool _isEditing = false;

  // --- NEW: Helper to get the initial date based on time ---
  DateTime _getInitialDate() {
    final now = DateTime.now();
    // Cutoff time is 9 PM (21:00)
    if (now.hour >= 21) {
      return DateUtils.dateOnly(now.add(const Duration(days: 1)));
    }
    return DateUtils.dateOnly(now);
  }

  @override
  void initState() {
    super.initState();
    // --- MODIFIED: Use the new helper ---
    _selectedDate = _getInitialDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForSelectedDate();
    });
  }

  Future<void> _fetchDataForSelectedDate({bool forceRefresh = false}) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final myBookingsProvider =
        Provider.of<MyBookingsProvider>(context, listen: false);

    await Future.wait([
      menuProvider.fetchMenuForDate(_selectedDate, forceRefresh: forceRefresh),
      myBookingsProvider.fetchBookingHistory(forceRefresh: forceRefresh),
    ]);
  }

  void _onMealSelected(String mealType, String item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMeals[mealType]!.add(item);
      } else {
        _selectedMeals[mealType]!.remove(item);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    // --- MODIFIED: Date logic is now dynamic ---
    final now = DateTime.now();
    final firstBookableDate = (now.hour >= 21)
        ? DateUtils.dateOnly(now.add(const Duration(days: 1)))
        : DateUtils.dateOnly(now);
    // --- END MODIFICATION ---

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstBookableDate, // Use dynamic first date
      lastDate: firstBookableDate.add(const Duration(days: 7)), // 7 days from the first bookable day
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isEditing = false;
        _selectedMeals['lunch']!.clear();
        _selectedMeals['dinner']!.clear();
      });
      Provider.of<MenuProvider>(context, listen: false).fetchMenuForDate(picked);
    }
  }

  void _submitBooking() async {
    if (_isEditing) {
      final bool? confirmed = await _showConfirmationDialog(
        context: context,
        title: 'Confirm Update',
        content:
            'Are you sure you want to update your booking with the new selections?',
        confirmText: 'Update',
        confirmColor: Colors.blue,
      );
      if (confirmed != true) {
        return;
      }
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bool success = await bookingProvider.submitBooking(
      date: _selectedDate,
      lunchPicks: _selectedMeals['lunch']!,
      dinnerPicks: _selectedMeals['dinner']!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (_isEditing ? 'Booking updated!' : 'Booking confirmed!')
              : bookingProvider.error ?? 'An error occurred.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        setState(() => _isEditing = false);
        Provider.of<MyBookingsProvider>(context, listen: false)
            .fetchBookingHistory(forceRefresh: true);
      }
    }
  }

  void _deleteBooking() async {
    final bool? confirmed = await _showConfirmationDialog(
      context: context,
      title: 'Confirm Deletion',
      content:
          'Are you sure you want to delete your booking for this date? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<BookingProvider>(context, listen: false)
          .cancelBooking(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Booking for this date has been deleted.'
                : 'Failed to delete booking.'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
        if (success) {
          Provider.of<MyBookingsProvider>(context, listen: false)
              .fetchBookingHistory(forceRefresh: true);
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    Color confirmColor = Colors.red,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isMessActive = authProvider.user?.isMessActive ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // --- MODIFIED: Using the new date selector ---
              _buildModernDateSelector(theme),
              Expanded(
                // --- REPLACED LiquidPullToRefresh with RefreshIndicator ---
                child: RefreshIndicator(
                  onRefresh: () =>
                      _fetchDataForSelectedDate(forceRefresh: true),
                  color: theme.colorScheme.primary,
                  child: Consumer2<MenuProvider, MyBookingsProvider>(
                    builder:
                        (context, menuProvider, myBookingsProvider, child) {
                      if (menuProvider.isLoading ||
                          myBookingsProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (menuProvider.error != null) {
                        return _buildInfoMessage(
                            lottieAsset: 'assets/not_found.json',
                            message: menuProvider.error!);
                      }

                      final existingBooking =
                          myBookingsProvider.bookingHistory.firstWhere(
                        (booking) => DateUtils.isSameDay(
                            booking.bookingDate.toLocal(), _selectedDate),
                        orElse: () => BookingHistoryItem(
                            bookingDate: _selectedDate,
                            lunchPick: null,
                            dinnerPick: null),
                      );

                      final bool bookingExists =
                          existingBooking.lunchPick != null ||
                              existingBooking.dinnerPick != null;

                      if (bookingExists && !_isEditing) {
                        // --- MODIFIED: Using the new booked state view ---
                        return _buildBookedStateView(theme, existingBooking);
                      } else {
                        return _buildSelectionStateView(
                            theme, menuProvider.menu, isMessActive);
                      }
                    },
                  ),
                ),
                // --- END OF REPLACEMENT ---
              ),
            ],
          ),
          if (!isMessActive) _buildInactiveMessOverlay(theme),
        ],
      ),
    );
  }

  // --- NEW WIDGET: Modern Date Selector Header ---
  Widget _buildModernDateSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(30.0)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectDate(context),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30.0)),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 28.0), // More padding
            child: SafeArea(
              bottom: false, // SafeArea is only for the top
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BOOKING FOR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined,
                      color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // --- END OF NEW WIDGET ---

  Widget _buildBookedStateView(ThemeData theme, BookingHistoryItem booking) {
    final lunchItems = booking.lunchPick ?? [];
    final dinnerItems = booking.dinnerPick ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          // --- MODIFIED: Using the new booked card ---
          _buildBookedMealCard(
              theme, 'Lunch', Icons.wb_sunny_outlined, lunchItems),
          const SizedBox(height: 20),
          _buildBookedMealCard(
              theme, 'Dinner', Icons.nightlight_round_outlined, dinnerItems),
          const SizedBox(height: 24),
          _buildBookedActionButtons(theme, booking),
        ],
      ),
    );
  }

  // --- NEW WIDGET: Redesigned "Booked" Card ---
  Widget _buildBookedMealCard(
      ThemeData theme, String title, IconData icon, List<String> items) {
    final isDarkMode = theme.brightness == Brightness.dark;
    bool isBooked = items.isNotEmpty;

    // Define colors for lunch/dinner
    LinearGradient headerGradient;
    Color iconColor;
    if (title == 'Lunch') {
      headerGradient = isDarkMode
          ? LinearGradient(colors: [
              Colors.orange.shade700,
              Colors.orange.shade500,
            ])
          : const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFFCC33)]);
      iconColor = isDarkMode ? Colors.orange.shade200 : Colors.orange.shade800;
    } else {
      headerGradient = isDarkMode
          ? LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900])
          : const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]);
      iconColor = isDarkMode ? Colors.purple.shade200 : Colors.indigo.shade800;
    }

    return Card(
      elevation: 6.0,
      shadowColor:
          (title == 'Lunch' ? Colors.orange : Colors.indigo).withOpacity(0.2),
      clipBehavior: Clip.antiAlias, // Ensures content respects the border radius
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            decoration: BoxDecoration(
              gradient: headerGradient,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: isBooked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map((item) => _buildBookedItemRow(theme, item))
                        .toList(),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'No meal selected for this slot.',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- NEW WIDGET: Helper for "Booked" Card Item ---
  Widget _buildBookedItemRow(ThemeData theme, String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item,
              style:
                  theme.textTheme.bodyLarge?.copyWith(height: 1.4, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedActionButtons(ThemeData theme, BookingHistoryItem booking) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final deleteColor = isDarkMode ? Colors.red.shade300 : Colors.red;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _deleteBooking,
            icon: Icon(Icons.delete_outline, color: deleteColor),
            label: Text('Delete', style: TextStyle(color: deleteColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: deleteColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedMeals['lunch'] =
                    List<String>.from(booking.lunchPick ?? []);
                _selectedMeals['dinner'] =
                    List<String>.from(booking.dinnerPick ?? []);
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionStateView(
      ThemeData theme, DailyMenu? menu, bool isMessActive) {
    if (menu == null) {
      return _buildInfoMessage(
          lottieAsset: 'assets/no-food.json',
          message: "No menu is set for this day.");
    }
    final bool isMealSelected = _selectedMeals['lunch']!.isNotEmpty ||
        _selectedMeals['dinner']!.isNotEmpty;
    final isDarkMode = theme.brightness == Brightness.dark;
    final lunchIconColor = isDarkMode ? theme.colorScheme.primary : Colors.orange;
    final dinnerIconColor =
        isDarkMode ? Colors.deepPurple.shade300 : Colors.indigo;

    return Column(
      children: [
        Expanded(
          child: AnimationLimiter(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
                children: [
                  _buildMealSelectionCard(theme, 'Lunch',
                      Icons.wb_sunny_outlined, lunchIconColor, menu.lunchOptions, 'lunch'),
                  const SizedBox(height: 20),
                  _buildMealSelectionCard(theme, 'Dinner',
                      Icons.nightlight_round_outlined, dinnerIconColor, menu.dinnerOptions, 'dinner'),
                ],
              ),
            ),
          ),
        ),
        if (isMealSelected || _isEditing)
          _buildSelectionActionButtons(isMessActive),
      ],
    );
  }

  Widget _buildMealSelectionCard(ThemeData theme, String title, IconData icon,
      Color color, List<String> options, String mealType) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: theme.cardTheme.color,
        gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  theme.cardTheme.color!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? color
                        : theme.textTheme.headlineSmall?.color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (options.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options[index];
                  final isSelected = _selectedMeals[mealType]!.contains(item);
                  return _buildMealGridItem(theme, item, isSelected,
                      (bool? value) {
                    _onMealSelected(mealType, item, value ?? false);
                  });
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                    child: Text("No menu set for this meal.",
                        style: TextStyle(fontSize: 16, color: Colors.grey))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealGridItem(ThemeData theme, String item, bool isSelected,
      ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActionButtons(bool isMessActive) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_isEditing)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel Update'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_isEditing) const SizedBox(width: 16),
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, provider, child) => ElevatedButton.icon(
                onPressed:
                    isMessActive && !provider.isSubmitting ? _submitBooking : null,
                icon: const Icon(Icons.check_circle_outline),
                label: provider.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Update' : 'Confirm'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      _isEditing ? theme.colorScheme.primary : Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveMessOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_food, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 20),
              Text('Your Mess is Inactive',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  'Please contact the mess committee for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoMessage(
      {required String lottieAsset, required String message}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                lottieAsset,
                width: 250,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}