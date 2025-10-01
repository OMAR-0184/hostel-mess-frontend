// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/booking_provider.dart';
import '../provider/menu_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- CORE LOGIC - UNCHANGED ---
  DateTime _selectedDate = DateTime.now();
  final Map<String, List<String>> _selectedMeals = {'lunch': [], 'dinner': []};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchMenuForDate(_selectedDate);
    });
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedMeals['lunch']!.clear();
        _selectedMeals['dinner']!.clear();
      });
      Provider.of<MenuProvider>(context, listen: false).fetchMenuForDate(picked);
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
          content: Text(success ? 'Booking submitted successfully!' : bookingProvider.error ?? 'An unknown error occurred.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _cancelBooking() async {
    final success = await Provider.of<BookingProvider>(context, listen: false).cancelBooking(_selectedDate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Booking for this date has been cancelled.' : 'Failed to cancel booking.'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }
  // --- END OF CORE LOGIC ---


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          _buildDateSelector(theme),
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, menuProvider, child) {
                if (menuProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (menuProvider.error != null) {
                  return _buildInfoMessage(icon: Icons.error_outline, message: menuProvider.error!);
                }
                if (menuProvider.menu == null) {
                  return _buildInfoMessage(icon: Icons.calendar_today_outlined, message: 'Please select a date to see the menu.');
                }

                final menu = menuProvider.menu!;
                return AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 400),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildBookingCard(theme, 'Lunch', Icons.wb_sunny_outlined, Colors.orange, menu.lunchOptions, 'lunch'),
                        const SizedBox(height: 20),
                        _buildBookingCard(theme, 'Dinner', Icons.nightlight_round_outlined, Colors.indigo, menu.dinnerOptions, 'dinner'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Action buttons remain at the bottom, unchanged in logic
          _buildActionButtons(),
        ],
      ),
    );
  }

  // --- MODERNIZED UI WIDGETS ---

  Widget _buildDateSelector(ThemeData theme) {
     return Padding(
       padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
       child: InkWell(
         onTap: () => _selectDate(context),
         borderRadius: BorderRadius.circular(15.0),
         child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
         ),
       ),
     );
  }

  Widget _buildBookingCard(ThemeData theme, String title, IconData icon, Color color, List<String> options, String mealType) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            if (options.isNotEmpty)
              ...options.map((item) {
                final isSelected = _selectedMeals[mealType]!.contains(item);
                return _buildMealItem(theme, item, isSelected, (bool? value) {
                  // This calls the original, unchanged logic
                  _onMealSelected(mealType, item, value ?? false);
                });
              }).toList()
            else
              const Padding(
                 padding: EdgeInsets.symmetric(vertical: 20.0),
                 child: Center(child: Text("No menu set for this meal.", style: TextStyle(fontSize: 16, color: Colors.grey))),
              ),
          ],
        ),
      ),
    );
  }

  /// A custom, modern checkbox-like tile for meal items.
  Widget _buildMealItem(ThemeData theme, String item, bool isSelected, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : Colors.white,
                border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
           Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelBooking,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                 textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, provider, child) => ElevatedButton.icon(
                onPressed: provider.isSubmitting ? null : _submitBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: provider.isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                ),
              ),
            ),
          ),
        ],
      ),
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