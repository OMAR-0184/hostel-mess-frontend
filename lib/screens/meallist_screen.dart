// lib/screens/meallist_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Still needed for colors
import 'package:open_filex/open_filex.dart';
import '../provider/admin_provider.dart';
import '../services/pdf_export_service.dart'; 

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MealListScreen extends StatefulWidget {
  const MealListScreen({Key? key}) : super(key: key);

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGeneratingPdf = false;

  // --- REMOVED GlobalKeys ---
  // final GlobalKey _lunchChartKey = GlobalKey();
  // final GlobalKey _dinnerChartKey = GlobalKey();

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

  // --- REMOVED _captureWidget function ---

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
      // --- REMOVED chart capturing logic ---

      // --- MODIFIED CALL (This is the FIX) ---
      // Now only passes the mealList, matching the PDF service
      final Uint8List pdfBytes = await PdfExportService.generateMealListPdf(
        adminProvider.mealList!,
      );
      // --- END OF FIX ---

      final dateString =
          DateFormat('yyyy-MM-dd').format(adminProvider.mealList!.bookingDate);
      final pdfName = 'MealList_$dateString.pdf';

      if (kIsWeb) {
        // WEB
        await Printing.sharePdf(bytes: pdfBytes, filename: pdfName);
      } else {
        // MOBILE
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
        actions: [
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
                    // --- MODIFIED CALLS (no keys) ---
                    _buildItemChart(
                      "Lunch Breakdown",
                      Icons.wb_sunny,
                      Colors.orange,
                      mealList.lunchItemCounts,
                    ),
                    _buildItemChart(
                      "Dinner Breakdown",
                      Icons.nights_stay,
                      Colors.indigo,
                      mealList.dinnerItemCounts,
                    ),
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
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  /// This widget builds the legend as a Grid
  Widget _buildLegend(ThemeData theme, Map<String, dynamic> items) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final entries = items.entries.toList(); // Convert map to list to access by index

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // IMPORTANT: It's inside a ListView
      shrinkWrap: true, // IMPORTANT: It's inside a ListView
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0, // Each column will be at least 200px wide
        mainAxisExtent: 60.0,       // Each item will have a fixed height of 60px
        crossAxisSpacing: 10.0,     // Space between columns
        mainAxisSpacing: 10.0,      // Space between rows
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final itemColor = _chartColors[index % _chartColors.length]; // Simpler index
        
        // This is the same widget as before, just arranged in a grid
        return Row(
          children: [
            Container(width: 12, height: 12, color: itemColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  Text(
                    entry.key, // The item name
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long names
                    maxLines: 2,
                  ),
                  Text(
                    '(${entry.value})', // The count
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIED FUNCTION SIGNATURE (no key) ---
  Widget _buildItemChart(String title, IconData icon, Color color,
      Map<String, dynamic> items) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
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
            const Divider(height: 20),

            // --- REMOVED hidden chart block ---
            
            // 2. THIS WIDGET IS VISIBLE ON THE SCREEN
            // It contains *only* the counts/legend, now in a Grid.
            Container(
              color: theme.cardTheme.color,
              padding: const EdgeInsets.all(16.0),
              child: items.isEmpty
                  ? const SizedBox(
                      height: 150, // Keep height consistent
                      child: Center(child: Text('No items for this meal')))
                  : _buildLegend(theme, items), // Use the new grid legend
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET TO BUILD THE ROOM CHIP ---
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
  // --- END HELPER WIDGET ---

  // --- WIDGET TO BUILD LUNCH/DINNER ROWS ---
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
                : const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      ],
    );
  }
  // --- END HELPER WIDGET ---


  Widget _buildBookingsListCard(
      String title, IconData icon, Color color, List<MealListItem> bookings) {
    // --- THIS WIDGET IS NOW MODIFIED ---
    final theme = Theme.of(context);
    
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
        initiallyExpanded: true,
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
              // --- REPLACED LISTTILE WITH CUSTOM WIDGET ---
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
              // --- END OF REPLACEMENT ---
            },
          )
        ],
      ),
    );
  }
}