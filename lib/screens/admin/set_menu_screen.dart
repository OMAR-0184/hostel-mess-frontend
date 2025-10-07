// lib/screens/admin/set_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../provider/admin_provider.dart';
import '../../provider/menu_provider.dart';

class SetMenuScreen extends StatefulWidget {
  const SetMenuScreen({Key? key}) : super(key: key);

  @override
  _SetMenuScreenState createState() => _SetMenuScreenState();
}

class _SetMenuScreenState extends State<SetMenuScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<String> _lunchItems = [];
  final List<String> _dinnerItems = [];
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  bool _menuExists = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMenuForSelectedDate();
    });
  }

  Future<void> _fetchMenuForSelectedDate() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.fetchMenuForDate(_selectedDate);
    final menu = menuProvider.menu;
    setState(() {
      _lunchItems.clear();
      _dinnerItems.clear();
      if (menu != null && DateUtils.isSameDay(menu.menuDate, _selectedDate)) {
        _lunchItems.addAll(menu.lunchOptions);
        _dinnerItems.addAll(menu.dinnerOptions);
        _menuExists = true;
      } else {
        _menuExists = false;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchMenuForSelectedDate();
    }
  }

  void _submitMenu() async {
    if (_lunchItems.isEmpty && _dinnerItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save an empty menu. Please add at least one item.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.setDailyMenu(
      date: _selectedDate,
      lunchOptions: _lunchItems,
      dinnerOptions: _dinnerItems,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Menu updated successfully!' : adminProvider.error ?? 'Failed to update menu.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Provider.of<MenuProvider>(context, listen: false).clearMenuForDate(_selectedDate);
        Navigator.of(context).pop();
      }
    }
  }

  void _clearMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Menu?'),
          content: Text('Are you sure you want to clear the entire menu for ${DateFormat('d MMMM').format(_selectedDate)}?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                  Navigator.of(context).pop();

                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  // Set an empty menu to effectively "delete" it
                  final success = await adminProvider.setDailyMenu(
                    date: _selectedDate,
                    lunchOptions: [],
                    dinnerOptions: [],
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Menu cleared successfully!' : 'Failed to clear menu.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) {
                      Provider.of<MenuProvider>(context, listen: false).clearMenuForDate(_selectedDate);
                      _fetchMenuForSelectedDate(); // Refresh the screen state
                    }
                  }
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
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Set Daily Menu'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          if (_menuExists)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearMenu,
              tooltip: 'Clear Entire Menu',
            )
        ],
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildDateSelector(theme),
              const SizedBox(height: 24),
              _buildMealSection(theme, 'Lunch', Icons.wb_sunny_outlined, Colors.orange, _lunchItems, _lunchController),
              const SizedBox(height: 20),
              _buildMealSection(theme, 'Dinner', Icons.nightlight_round_outlined, Colors.indigo, _dinnerItems, _dinnerController),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _selectDate(context),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(ThemeData theme, String title, IconData icon, Color color, List<String> items, TextEditingController controller) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4.0,
      shadowColor: color.withOpacity(0.2), // Shadow color now matches the tone
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent, // Make card transparent to show container color
      child: Container(
        // The container now provides the tinted background color
        decoration: BoxDecoration(
          color: isDarkMode ? color.withOpacity(0.25) : color.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28), // Icon color is always the main highlight color
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (items.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: items.map((item) {
                    // Determine text color based on the chip's background color luminance
                    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                    return Chip(
                      label: Text(item, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      backgroundColor: color, // Use the section's highlight color
                      deleteIcon: Icon(Icons.close, size: 18, color: textColor),
                      onDeleted: () {
                        setState(() {
                          items.remove(item);
                        });
                      },
                    );
                  }).toList(),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Text("No items added yet.", style: TextStyle(fontSize: 16, color: Colors.grey))),
                ),
              const SizedBox(height: 20),
              _buildAddItemField(items, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemField(List<String> items, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Add new item...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  items.add(value.trim());
                  controller.clear();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              setState(() {
                items.add(controller.text.trim());
                controller.clear();
              });
            }
          },
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            foregroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (provider.isSubmitting ?? false) ? null : _submitMenu,
          icon: const Icon(Icons.save_alt_rounded),
          label: (provider.isSubmitting ?? false)
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_menuExists ? 'Update Menu' : 'Save Menu'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    );
  }
}