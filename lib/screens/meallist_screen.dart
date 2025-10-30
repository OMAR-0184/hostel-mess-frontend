// lib/screens/meallist_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class MealListScreen extends StatefulWidget {
  const MealListScreen({Key? key}) : super(key: key);

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGeneratingPdf = false;

  // Re-added keys to capture chart images
  final GlobalKey _lunchChartKey = GlobalKey();
  final GlobalKey _dinnerChartKey = GlobalKey();

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

  // Re-added function to capture widget as an image
  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Error capturing widget: $e");
      return null;
    }
  }

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
      // Re-enabled capturing the chart images
      final lunchChartImage = await _captureWidget(_lunchChartKey);
      final dinnerChartImage = await _captureWidget(_dinnerChartKey);

      if (lunchChartImage == null || dinnerChartImage == null) {
        throw Exception("Failed to capture chart images.");
      }

      // This line calls the service class
      final Uint8List pdfBytes = await PdfExportService.generateMealListPdf(
        adminProvider.mealList!,
        lunchChartImage,
        dinnerChartImage,
      );

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
                    _buildItemChart( // Back to _buildItemChart
                      "Lunch Breakdown",
                      Icons.wb_sunny,
                      Colors.orange,
                      mealList.lunchItemCounts,
                      _lunchChartKey,
                    ),
                    _buildItemChart( // Back to _buildItemChart
                      "Dinner Breakdown",
                      Icons.nights_stay,
                      Colors.indigo,
                      mealList.dinnerItemCounts,
                      _dinnerChartKey,
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

  // This is the original Pie Chart widget, but with the legend fixed
  Widget _buildItemChart(String title, IconData icon, Color color,
      Map<String, dynamic> items, GlobalKey chartKey) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    double total = items.values.fold(0, (sum, item) => sum + item);
    int colorIndex = 0;

    List<PieChartSectionData> sections = items.entries.map((entry) {
      final color = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

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
            RepaintBoundary(
              key: chartKey,
              child: Container(
                color: theme.cardTheme.color,
                padding: const EdgeInsets.all(16.0),
                child: items.isEmpty
                    ? const SizedBox(
                        height: 150,
                        child: Center(child: Text('No items for this meal')))
                    : Row(
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 30,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items.entries.map((entry) {
                                final itemColor = _chartColors[
                                    items.keys.toList().indexOf(entry.key) %
                                        _chartColors.length];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        color: itemColor,
                                      ),
                                      const SizedBox(width: 8),
                                      // --- FIX ---
                                      // Changed this from an overflowing Text widget
                                      // to a Column to prevent text from hiding counts.
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.key, // The item name
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
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
                                      // --- END FIX ---
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
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