import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart'; // Import the lottie package
import '../provider/menu_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch the menu for today when the screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchMenuForDate(_selectedDate);
    });
  }

  /// Shows a date picker and fetches the menu for the selected date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Provider.of<MenuProvider>(context, listen: false).fetchMenuForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, menuProvider, child) {
                if (menuProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // MODIFIED: Use the new animated info message for errors
                if (menuProvider.error != null) {
                  return _buildInfoMessage(
                    lottieAsset: 'assets/not_found.json',
                    message: menuProvider.error!,
                  );
                }
                if (menuProvider.menu != null) {
                  return _buildMenuDisplay(menuProvider.menu!);
                }
                // MODIFIED: Use the new animated info message for when no menu is set
                return _buildInfoMessage(
                  lottieAsset: 'assets/no-food.json',
                  message: 'No menu is set for this date.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('EEEE, d MMMM').format(_selectedDate),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDisplay(DailyMenu menu) {
    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            _buildMealCard('Lunch', Icons.wb_sunny, Colors.orange, menu.lunchOptions),
            const SizedBox(height: 16),
            _buildMealCard('Dinner', Icons.nights_stay, Colors.indigo, menu.dinnerOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String title, IconData icon, Color color, List<String> items) {
     return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const Divider(color: Colors.white54, height: 20, thickness: 1),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('• $item', style: const TextStyle(fontSize: 18, color: Colors.white)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Replaced _buildInfoCard with this animated widget
  Widget _buildInfoMessage({required String lottieAsset, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            lottieAsset,
            width: 250,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}