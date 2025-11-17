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

class _BookingScreenState extends State<BookingScreen>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  final Map<String, List<String>> _selectedMeals = {'lunch': [], 'dinner': []};

  String? _editingMealType;

  bool _hasBooking = false;
  bool _isEditing = false;
  bool _isCreating = false;

  @override
  bool get wantKeepAlive => true;

  /// Sets the initial date.
  /// Defaults to the next day if it's 9 PM (21:00) or later.
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

  @override
  void dispose() {
    super.dispose();
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
      final existingBooking = myBookingsProvider.bookingHistory.firstWhere(
        (b) => DateUtils.isSameDay(b.bookingDate.toLocal(), _selectedDate),
        orElse: () => BookingHistoryItem(bookingDate: _selectedDate),
      );

      setState(() {
        _editingMealType = null;
        _selectedMeals['lunch'] = List.from(existingBooking.lunchPick ?? []);
        _selectedMeals['dinner'] = List.from(existingBooking.dinnerPick ?? []);
      });
    }
  }

  void _toggleMealSelection(String mealType, String item, bool isSelected) {
    final history =
        Provider.of<MyBookingsProvider>(context, listen: false).bookingHistory;
    final existingBooking = history.firstWhere(
      (b) => DateUtils.isSameDay(b.bookingDate.toLocal(), _selectedDate),
      orElse: () => BookingHistoryItem(bookingDate: _selectedDate),
    );
    final bool hasBooking = (existingBooking.lunchPick?.isNotEmpty ?? false) ||
        (existingBooking.dinnerPick?.isNotEmpty ?? false);

    setState(() {
      if (isSelected) {
        _selectedMeals[mealType]!.add(item);
      } else {
        _selectedMeals[mealType]!.remove(item);
      }

      if (hasBooking) {
        _editingMealType = mealType;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();

    // Allow user to select current day from calendar regardless of time
    final firstBookableDate = DateUtils.dateOnly(now);

    final DateTime? picked = await showDatePicker(
      context: context,
      // Ensure initialDate is valid (must be >= firstDate)
      initialDate: _selectedDate.isBefore(firstBookableDate)
          ? firstBookableDate
          : _selectedDate,
      firstDate: firstBookableDate,
      lastDate: firstBookableDate.add(const Duration(days: 14)),
    );

    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchDataForSelectedDate();
    }
  }

  void _submitBooking() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    bool success = false;
    String successMessage = 'Booking confirmed successfully! ✅';
    String? errorMessage = 'An error occurred.';

    if (_isCreating) {
      success = await bookingProvider.submitBooking(
        date: _selectedDate,
        lunchPicks: _selectedMeals['lunch']!,
        dinnerPicks: _selectedMeals['dinner']!,
      );
      errorMessage = bookingProvider.error ?? 'Failed to submit booking.';
    } else if (_isEditing) {
      if (_editingMealType == 'lunch') {
        success = await bookingProvider.updateLunchBooking(
            _selectedDate, _selectedMeals['lunch']!);
        successMessage = 'Lunch booking updated! ✅';
        errorMessage = bookingProvider.error ?? 'Failed to update lunch.';
      } else if (_editingMealType == 'dinner') {
        success = await bookingProvider.updateDinnerBooking(
            _selectedDate, _selectedMeals['dinner']!);
        successMessage = 'Dinner booking updated! ✅';
        errorMessage = bookingProvider.error ?? 'Failed to update dinner.';
      } else {
        success = false;
        errorMessage = "Error: No meal selected for editing.";
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? successMessage : errorMessage!),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        Provider.of<MyBookingsProvider>(context, listen: false)
            .fetchBookingHistory(forceRefresh: true);
        _fetchDataForSelectedDate(forceRefresh: true);
      }
    }
  }

  void _cancelDailyBooking() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel All Bookings?'),
        content: const Text(
            'Are you sure you want to cancel ALL meals for this date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel All',
                style: TextStyle(color: Colors.red)),
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
          _fetchDataForSelectedDate(forceRefresh: true);
        }
      }
    }
  }

  void _cancelSingleMeal(
      String mealType, BookingProvider bookingProvider) async {
    final mealTitle = mealType == 'lunch' ? 'Lunch' : 'Dinner';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel $mealTitle?'),
        content: Text(
            'Are you sure you want to cancel your $mealTitle booking? This will keep your other bookings for the day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, Cancel $mealTitle',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      bool success = false;

      if (mealType == 'lunch') {
        success = await bookingProvider.updateLunchBooking(_selectedDate, []);
      } else {
        success = await bookingProvider.updateDinnerBooking(_selectedDate, []);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '$mealTitle cancelled successfully.'
                : 'Failed to cancel $mealTitle.'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) {
          _fetchDataForSelectedDate(forceRefresh: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMessActive = authProvider.user?.isMessActive ?? false;
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Color> lunchGradient = [
      const Color(0xFF4568DC),
      const Color(0xFF007BFF)
    ];
    final List<Color> dinnerGradient = [
      const Color(0xFFB06AB3),
      const Color(0xFF9333EA)
    ];

    // Determine state based on fetched data to drive UI logic
    final history = Provider.of<MyBookingsProvider>(context).bookingHistory;
    final existingBooking = history.firstWhere(
      (b) => DateUtils.isSameDay(b.bookingDate.toLocal(), _selectedDate),
      orElse: () => BookingHistoryItem(bookingDate: _selectedDate),
    );

    _hasBooking = (existingBooking.lunchPick?.isNotEmpty ?? false) ||
        (existingBooking.dinnerPick?.isNotEmpty ?? false);

    _isEditing = _hasBooking && _editingMealType != null;

    final bool lunchChanged = _selectedMeals['lunch']!.toSet().toString() !=
        (existingBooking.lunchPick ?? []).toSet().toString();
    final bool dinnerChanged = _selectedMeals['dinner']!.toSet().toString() !=
        (existingBooking.dinnerPick ?? []).toSet().toString();
    final bool hasChanges = lunchChanged || dinnerChanged;

    _isCreating = !_hasBooking && hasChanges;

    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'BOOK A MEAL',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1.0,
            ),
          ),
        ),
        body: Stack(
          children: [
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
            Positioned(
              top: -100,
              left: -50,
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
            RefreshIndicator(
              onRefresh: () => _fetchDataForSelectedDate(forceRefresh: true),
              child: Column(
                children: [
                  _buildModernDateHeader(theme, lunchGradient),
                  Expanded(
                    child: Consumer3<MenuProvider, MyBookingsProvider,
                        BookingProvider>(
                      builder: (context, menuProvider, myBookingsProvider,
                          bookingProvider, child) {
                        if (menuProvider.isLoading ||
                            myBookingsProvider.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final bool isLunchBooked =
                            existingBooking.lunchPick?.isNotEmpty ?? false;
                        final bool isDinnerBooked =
                            existingBooking.dinnerPick?.isNotEmpty ?? false;

                        if (menuProvider.menu == null) {
                          return _buildEmptyState(theme);
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 16.0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 400),
                                childAnimationBuilder: (widget) =>
                                    SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                                children: [
                                  _buildModernMealCard(
                                    theme,
                                    bookingProvider: bookingProvider,
                                    title: 'Lunch',
                                    icon: Icons.wb_sunny_rounded,
                                    gradientColors: lunchGradient,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                    menuItems: menuProvider.menu!.lunchOptions,
                                    selectedItems: _selectedMeals['lunch']!,
                                    isBooked: isLunchBooked,
                                    mealType: 'lunch',
                                    hasBooking: _hasBooking,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildModernMealCard(
                                    theme,
                                    bookingProvider: bookingProvider,
                                    title: 'Dinner',
                                    icon: Icons.nights_stay_rounded,
                                    gradientColors: dinnerGradient,
                                    shadowColor: Colors.purple.withOpacity(0.3),
                                    menuItems: menuProvider.menu!.dinnerOptions,
                                    selectedItems: _selectedMeals['dinner']!,
                                    isBooked: isDinnerBooked,
                                    mealType: 'dinner',
                                    hasBooking: _hasBooking,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  isMessActive
                      ? _buildBottomActionBar(theme, hasChanges)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: null,
      ),
    );
  }

  Widget _buildModernMealCard(
    ThemeData theme, {
    required BookingProvider bookingProvider,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required List<String> menuItems,
    required List<String> selectedItems,
    required bool isBooked,
    required String mealType,
    required bool hasBooking,
  }) {
    final bool hasSelection = selectedItems.isNotEmpty;
    final bool isCurrentlyEditingThisMeal = _editingMealType == mealType;

    final bool isLocked =
        hasBooking && _editingMealType != null && !isCurrentlyEditingThisMeal;

    return AbsorbPointer(
      absorbing: isLocked,
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? Colors.grey.withOpacity(0.1)
                    : (hasSelection || isBooked
                        ? shadowColor
                        : Colors.black.withOpacity(0.05)),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(
              color: isLocked
                  ? Colors.grey.shade400
                  : (hasSelection || isBooked
                      ? gradientColors.last
                      : Colors.transparent),
              width: isLocked ? 1.0 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Header with Gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLocked
                          ? [
                              Colors.grey.withOpacity(0.05),
                              Colors.grey.withOpacity(0.1)
                            ]
                          : [
                              gradientColors.first.withOpacity(0.1),
                              gradientColors.last.withOpacity(0.2)
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
                          Icon(icon,
                              color: isLocked
                                  ? Colors.grey.shade600
                                  : gradientColors.last,
                              size: 24),
                          const SizedBox(width: 12),
                          Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: isLocked
                                      ? Colors.grey.shade600
                                      : gradientColors.last,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                      if (isBooked && !isCurrentlyEditingThisMeal && !isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text("BOOKED",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                        ),
                      if (isLocked && isBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade600),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock,
                                  size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text("LOCKED",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                if (menuItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                        child: Text("No menu set.",
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic))),
                  )
                else if (isLocked && isBooked)
                  _buildLockedView(theme, selectedItems)
                else if (isBooked && !isCurrentlyEditingThisMeal)
                  _buildSummaryView(
                      theme, selectedItems, mealType, bookingProvider)
                else if (!isBooked || isCurrentlyEditingThisMeal)
                  _buildSelectionView(theme, menuItems, selectedItems, mealType,
                      gradientColors, bookingProvider)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateHeader(ThemeData theme, List<Color> blueGradient) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: blueGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BOOKING FOR:",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE').format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM d, y').format(_selectedDate),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1)),
                child: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => _selectDate(context),
                  tooltip: 'Change Date',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionView(
      ThemeData theme,
      List<String> menuItems,
      List<String> selectedItems,
      String mealType,
      List<Color> gradientColors,
      BookingProvider bookingProvider) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool hasSelection = selectedItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ...menuItems.map((item) {
            final bool itemSelected = selectedItems.contains(item);

            final Color color =
                itemSelected ? gradientColors.last : Colors.grey.shade400;
            final Color bgColor = itemSelected
                ? gradientColors.last.withOpacity(isDarkMode ? 0.2 : 0.1)
                : theme.scaffoldBackgroundColor;
            final Color borderColor =
                itemSelected ? gradientColors.last : Colors.transparent;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: itemSelected
                      ? [
                          BoxShadow(
                            color: gradientColors.last.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : []),
              child: ListTile(
                onTap: () =>
                    _toggleMealSelection(mealType, item, !itemSelected),
                leading: Icon(
                  itemSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: color,
                ),
                title: Text(
                  item,
                  style: TextStyle(
                    fontWeight:
                        itemSelected ? FontWeight.bold : FontWeight.normal,
                    color: itemSelected
                        ? gradientColors.last
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
          if (hasSelection && _hasBooking) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _cancelSingleMeal(mealType, bookingProvider),
              icon: Icon(Icons.delete_outline_rounded,
                  color: theme.colorScheme.error),
              label: Text(
                "Cancel This Meal",
                style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryView(ThemeData theme, List<String> selectedItems,
      String mealType, BookingProvider bookingProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You have booked:",
            style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ...selectedItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editingMealType = mealType),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Update",
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextButton(
                  onPressed: () => _cancelSingleMeal(mealType, bookingProvider),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Cancel",
                      style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLockedView(ThemeData theme, List<String> selectedItems) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You have booked:",
            style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ...selectedItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check,
                        size: 16, color: Colors.green.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  "Editing other meal",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  color: Colors.grey.shade600, fontWeight: FontWeight.bold),
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

  Widget _buildBottomActionBar(ThemeData theme, bool hasChanges) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: hasChanges && !bookingProvider.isSubmitting
                        ? [theme.colorScheme.primary, const Color(0xFFE100FF)]
                        : [Colors.grey, Colors.grey],
                  ),
                  boxShadow: hasChanges && !bookingProvider.isSubmitting
                      ? [
                          BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: hasChanges && !bookingProvider.isSubmitting
                      ? _submitBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: bookingProvider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _editingMealType == 'lunch'
                              ? "Update Lunch"
                              : "Update Dinner",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isEditing && _hasBooking) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _cancelDailyBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Cancel All Bookings",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }

    if (_isCreating) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: hasChanges && !bookingProvider.isSubmitting
                    ? _submitBooking
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: bookingProvider.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm Booking",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
