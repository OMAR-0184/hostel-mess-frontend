// lib/screens/meallist_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import '../provider/admin_provider.dart';
import '../services/pdf_export_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// MealListScreen StatefulWidget
class MealListScreen extends StatefulWidget {
  const MealListScreen({Key? key}) : super(key: key);

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

// _MealListScreenState
class _MealListScreenState extends State<MealListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGeneratingPdf = false;

  final List<Color> _chartColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.yellow.shade700,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          .fetchMealListForDate(_selectedDate);
    });
  }

  // Date selection logic
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

  // PDF download logic
  Future<void> _downloadPdf() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.mealList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final Uint8List pdfBytes = await PdfExportService.generateMealListPdf(
        adminProvider.mealList!,
      );

      final dateString =
          DateFormat('yyyy-MM-dd').format(adminProvider.mealList!.bookingDate);
      final pdfName = 'MealList_$dateString.pdf';

      if (kIsWeb) {
        // Web PDF sharing
        await Printing.sharePdf(bytes: pdfBytes, filename: pdfName);
      } else {
        // Mobile PDF saving and opening
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/$pdfName");
        await file.writeAsBytes(pdfBytes);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      print("Error generating PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isGeneratingPdf = false);
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // Screen AppBar
      appBar: AppBar(
        title: const Text('Daily Meal List'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          // PDF Download Button Consumer
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              if (adminProvider.mealList == null || adminProvider.isLoading) {
                return const SizedBox.shrink();
              }
              return _isGeneratingPdf
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: _downloadPdf,
                      tooltip: 'Download as PDF',
                    );
            },
          ),
        ],
      ),
      // Main Body
      body: Column(
        children: [
          // Date Selector Widget
          _buildDateSelector(),
          // Content Area
          Expanded(
            // AdminProvider Consumer
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
                // Main List of Cards
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 80.0),
                  children: [
                    _buildSummaryCard(mealList),
                    _buildItemChart(
                      theme,
                      "Lunch Breakdown",
                      Icons.wb_sunny,
                      Colors.orange,
                      mealList.lunchItemCounts,
                    ),
                    _buildItemChart(
                      theme,
                      "Dinner Breakdown",
                      Icons.nights_stay,
                      Colors.indigo,
                      mealList.dinnerItemCounts,
                    ),
                    _buildBookingsListCard(theme, "Student Bookings",
                        Icons.person, Colors.teal, mealList.bookings),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Date Selector Card Widget
  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  // Meal Booking Summary Card Widget
  Widget _buildSummaryCard(MealList mealList) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text("Meal Booking Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${mealList.totalLunchBookings} Lunch, ${mealList.totalDinnerBookings} Dinner'),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountColumn(
                    "Lunch", mealList.totalLunchBookings, Colors.orange),
                _buildCountColumn(
                    "Dinner", mealList.totalDinnerBookings, Colors.indigo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Count Column (for Summary Card)
  Widget _buildCountColumn(String title, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(),
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  // Legend Grid Widget (for Charts)
  Widget _buildLegend(ThemeData theme, Map<String, dynamic> items) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final entries = items.entries.toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisExtent: 60.0,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final itemColor = _chartColors[index % _chartColors.length];

        // Legend Item
        return Row(
          children: [
            Container(width: 12, height: 12, color: itemColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  // --- THIS IS THE MODIFIED WIDGET ---
                  Text(
                    'Count: ${entry.value}', // Added "Count:"
                    style: TextStyle(
                      fontSize: 13, // Slightly larger
                      color: theme.colorScheme.primary, // Use theme color
                      fontWeight: FontWeight.bold, // Make it bold
                    ),
                  ),
                  // --- END OF MODIFICATION ---
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Item Breakdown Card Widget
  Widget _buildItemChart(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    Map<String, dynamic> items,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        // --- MODIFIED SUBTITLE ---
        subtitle: Text(
          '${items.length} items',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        // --- END OF MODIFICATION ---
        children: [
          Container(
            color: theme.cardTheme.color,
            padding: const EdgeInsets.all(16.0),
            child: items.isEmpty
                ? const SizedBox(
                    height: 150,
                    child: Center(child: Text('No items for this meal')))
                : _buildLegend(theme, items),
          ),
        ],
      ),
    );
  }

  // Room Chip Widget (for Booking List)
  Widget _buildRoomChip(ThemeData theme, int roomNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.room_outlined, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Room: $roomNumber',
            style: TextStyle(
                color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Meal Items Row Widget (for Booking List)
  Widget _buildMealItems(ThemeData theme, String title, IconData icon,
      Color color, List<String> items) {
    final bool isBooked = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            isBooked ? items.join(', ') : 'Not Booked',
            style: isBooked
                ? theme.textTheme.bodyMedium
                : const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // Student Bookings List Card
  Widget _buildBookingsListCard(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    List<MealListItem> bookings,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        // --- MODIFIED SUBTITLE ---
        subtitle: Text(
          '${bookings.length} students',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        // --- END OF MODIFICATION ---
        initiallyExpanded: false,
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
              // Student Booking Item
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.userName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRoomChip(theme, booking.roomNumber),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildMealItems(
                      theme,
                      'Lunch',
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                      booking.lunchPick,
                    ),
                    const SizedBox(height: 12),
                    _buildMealItems(
                      theme,
                      'Dinner',
                      Icons.nightlight_round_outlined,
                      Colors.indigo,
                      booking.dinnerPick,
                    ),
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