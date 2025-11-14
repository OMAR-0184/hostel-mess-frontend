// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/booking_provider.dart';
import '../provider/menu_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/my_bookings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart'; 

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDate;
  final Map<String, List<String>> _selectedMeals = {'lunch': [], 'dinner': []};
  bool _isEditing = false;

  DateTime _getInitialDate() {
    final now = DateTime.now();
    if (now.hour >= 21) {
      return DateUtils.dateOnly(now.add(const Duration(days: 1)));
    }
    return DateUtils.dateOnly(now);
  }

  @override
  void initState() {
    super.initState();
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
    
    if (mounted) {
      setState(() {
        _isEditing = false;
        _selectedMeals['lunch']!.clear();
        _selectedMeals['dinner']!.clear();
      });
    }
  }

  void _toggleMealSelection(String mealType, String item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMeals[mealType]!.add(item);
      } else {
        _selectedMeals[mealType]!.remove(item);
      }
      _isEditing = true; 
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstBookableDate = (now.hour >= 21)
        ? DateUtils.dateOnly(now.add(const Duration(days: 1)))
        : DateUtils.dateOnly(now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstBookableDate,
      lastDate: firstBookableDate.add(const Duration(days: 14)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchDataForSelectedDate();
    }
  }

  void _submitBooking() async {
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
              ? 'Booking confirmed successfully! ✅'
              : bookingProvider.error ?? 'An error occurred.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        setState(() => _isEditing = false);
        Provider.of<MyBookingsProvider>(context, listen: false)
            .fetchBookingHistory(forceRefresh: true);
      }
    }
  }

  void _cancelBooking() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel meals for this date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<BookingProvider>(context, listen: false)
          .cancelBooking(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Booking cancelled.' : 'Failed to cancel.'),
            backgroundColor: success ? Colors.orange : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) {
          Provider.of<MyBookingsProvider>(context, listen: false)
              .fetchBookingHistory(forceRefresh: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMessActive = authProvider.user?.isMessActive ?? false;
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- FIX: Wrap the Scaffold in a SafeArea ---
    // This pushes the entire Scaffold (including its bottom nav bar) up
    // to avoid the main glass nav bar from home_screen.dart
    return SafeArea(
      top: false, // The AppBar from home_screen handles top padding
      bottom: true, // This is the crucial part
      child: Scaffold(
        // No solid background, allowing stack to show
        body: Stack(
          children: [
            // --- MODERN BACKGROUND GRADIENT MESH ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode 
                      ? [const Color(0xFF020617), const Color(0xFF0F172A)] // Dark Slate
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)], // Light Slate
                  ),
                ),
              ),
            ),
            // Accent Orb
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(isDarkMode ? 0.1 : 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(isDarkMode ? 0.1 : 0.05),
                      blurRadius: 100,
                      spreadRadius: 50,
                    )
                  ]
                ),
              ),
            ),

            // --- FIX: Removed the old SafeArea wrapper from here ---
            RefreshIndicator(
              onRefresh: () => _fetchDataForSelectedDate(forceRefresh: true),
              child: Column(
                children: [
                  _buildModernDateHeader(theme),
                  Expanded(
                    child: Consumer2<MenuProvider, MyBookingsProvider>(
                      builder: (context, menuProvider, myBookingsProvider, child) {
                        if (menuProvider.isLoading || myBookingsProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // Find existing booking for this date
                        final existingBooking = myBookingsProvider.bookingHistory.firstWhere(
                          (b) => DateUtils.isSameDay(b.bookingDate.toLocal(), _selectedDate),
                          orElse: () => BookingHistoryItem(bookingDate: _selectedDate),
                        );

                        final bool isBooked = (existingBooking.lunchPick?.isNotEmpty ?? false) ||
                                              (existingBooking.dinnerPick?.isNotEmpty ?? false);

                        if (!_isEditing && isBooked) {
                          _selectedMeals['lunch'] = List.from(existingBooking.lunchPick ?? []);
                          _selectedMeals['dinner'] = List.from(existingBooking.dinnerPick ?? []);
                        }

                        if (menuProvider.menu == null) {
                          return _buildEmptyState(theme);
                        }

                        return SingleChildScrollView(
                          // --- FIX: Removed manual bottom padding ---
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 400),
                                childAnimationBuilder: (widget) => SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                                children: [
                                  _buildModernMealCard(
                                    theme, 
                                    title: 'Lunch',
                                    icon: Icons.wb_sunny_rounded,
                                    gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)], // Orange Gradient
                                    shadowColor: Colors.orange.withOpacity(0.3),
                                    menuItems: menuProvider.menu!.lunchOptions, 
                                    selectedItems: _selectedMeals['lunch']!,
                                    isBooked: existingBooking.lunchPick?.isNotEmpty ?? false,
                                    mealType: 'lunch'
                                  ),
                                  const SizedBox(height: 24),
                                  _buildModernMealCard(
                                    theme, 
                                    title: 'Dinner',
                                    icon: Icons.nights_stay_rounded,
                                    gradientColors: [const Color(0xFF4568DC), const Color(0xFFB06AB3)], // Purple Gradient
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                    menuItems: menuProvider.menu!.dinnerOptions, 
                                    selectedItems: _selectedMeals['dinner']!,
                                    isBooked: existingBooking.dinnerPick?.isNotEmpty ?? false,
                                    mealType: 'dinner'
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isMessActive ? _buildBottomActionBar(theme) : null,
      ),
    );
  }

  // --- 1. Modern Glass-like Date Header ---
  Widget _buildModernDateHeader(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
              width: 1
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today_rounded, 
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, y').format(_selectedDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0
                        ),
                      ),
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. Modern Gradient Meal Card ---
  Widget _buildModernMealCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required List<String> menuItems,
    required List<String> selectedItems,
    required bool isBooked,
    required String mealType,
  }) {
    final bool hasSelection = selectedItems.isNotEmpty;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: hasSelection || isBooked ? shadowColor : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: hasSelection || isBooked ? gradientColors.last : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header with Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors.first.withOpacity(0.1),
                    gradientColors.last.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: gradientColors.last, size: 24),
                      const SizedBox(width: 12),
                      Text(title, style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 18,
                        color: gradientColors.last,
                        letterSpacing: 0.5
                      )),
                    ],
                  ),
                  if (isBooked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text("BOOKED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: menuItems.isEmpty 
                ? Center(child: Text("No menu set.", style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)))
                : Column(
                    children: menuItems.map((item) {
                      final bool itemSelected = selectedItems.contains(item);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: itemSelected 
                              ? gradientColors.last.withOpacity(isDarkMode ? 0.2 : 0.1) 
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: itemSelected ? gradientColors.last : Colors.transparent
                          )
                        ),
                        child: ListTile(
                          onTap: () => _toggleMealSelection(mealType, item, !itemSelected),
                          leading: Icon(
                            itemSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: itemSelected ? gradientColors.last : Colors.grey.shade400,
                          ),
                          title: Text(
                            item,
                            style: TextStyle(
                              fontWeight: itemSelected ? FontWeight.bold : FontWeight.normal,
                              color: itemSelected ? gradientColors.last : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Lottie Empty State ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/no-food.json', 
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              "Menu Not Published",
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "The mess convener hasn't updated the menu for this date yet. Please check back later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Floating Action Bar ---
  Widget _buildBottomActionBar(ThemeData theme) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final history = Provider.of<MyBookingsProvider>(context).bookingHistory;
    final hasBooking = history.any((b) => 
      DateUtils.isSameDay(b.bookingDate.toLocal(), _selectedDate) && 
      ((b.lunchPick?.isNotEmpty ?? false) || (b.dinnerPick?.isNotEmpty ?? false))
    );

    final bool hasSelections = _selectedMeals['lunch']!.isNotEmpty || _selectedMeals['dinner']!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          if (hasBooking)
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelBooking,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          if (hasBooking) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: (hasSelections || _isEditing) && !bookingProvider.isSubmitting
                      ? [theme.colorScheme.primary, const Color(0xFFE100FF)] // Active Gradient
                      : [Colors.grey, Colors.grey],
                ),
                boxShadow: (hasSelections || _isEditing) 
                    ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: (hasSelections || _isEditing) && !bookingProvider.isSubmitting 
                    ? _submitBooking 
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: bookingProvider.isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(hasBooking ? "Update Booking" : "Confirm Booking", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}