import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/admin_provider.dart';

class MealListScreen extends StatefulWidget {
  const MealListScreen({Key? key}) : super(key: key);

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          .fetchMealListForDate(_selectedDate);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Provider.of<AdminProvider>(context, listen: false)
          .fetchMealListForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Daily Meal List'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (adminProvider.error != null) {
                  return Center(child: Text(adminProvider.error!));
                }
                if (adminProvider.mealList == null) {
                  return const Center(
                      child: Text('No meal data found for this date.'));
                }
                final mealList = adminProvider.mealList!;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildSummaryCard(mealList),
                    _buildItemCountsCard("Lunch Breakdown", Icons.wb_sunny,
                        Colors.orange, mealList.lunchItemCounts),
                    _buildItemCountsCard("Dinner Breakdown", Icons.nights_stay,
                        Colors.indigo, mealList.dinnerItemCounts),
                    _buildBookingsListCard("Student Bookings", Icons.person,
                        Colors.teal, mealList.bookings),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(_selectedDate),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MealList mealList) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Meal Booking Summary",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountColumn(
                    "Lunch", mealList.totalLunchBookings, Colors.orange),
                _buildCountColumn(
                    "Dinner", mealList.totalDinnerBookings, Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountColumn(String title, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(),
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildItemCountsCard(
      String title, IconData icon, Color color, Map<String, dynamic> items) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: items.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 16)),
                      Text(entry.value.toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsListCard(
      String title, IconData icon, Color color, List<MealListItem> bookings) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        subtitle: Text('${bookings.length} students'),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                title: Text(booking.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Room: ${booking.roomNumber}"),
                    if (booking.lunchPick.isNotEmpty)
                      Text("Lunch: ${booking.lunchPick.join(', ')}",
                          style: const TextStyle(color: Colors.orange)),
                    if (booking.dinnerPick.isNotEmpty)
                      Text("Dinner: ${booking.dinnerPick.join(', ')}",
                          style: const TextStyle(color: Colors.indigo)),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}