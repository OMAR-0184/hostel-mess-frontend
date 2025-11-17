// lib/screens/meallist_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../provider/admin_provider.dart';
import '../services/pdf_export_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// --- MODIFICATION: Moved this class definition up ---
class MealListScreen extends StatefulWidget {
  const MealListScreen({Key? key}) : super(key: key);

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

// --- MODIFICATION: This class is now below its widget ---
class _MealListScreenState extends State<MealListScreen>
    with SingleTickerProviderStateMixin {
  // --- MODIFIED: Changed how _selectedDate is initialized ---
  late DateTime _selectedDate;
  bool _isGeneratingPdf = false;

  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<MealListItem> _filteredBookings = [];

  // --- NEW FUNCTION ---
  /// Gets the initial date based on the time.
  /// If it's 10 PM (22:00) or later, default to tomorrow.
  DateTime _getInitialDate() {
    final now = DateTime.now();
    if (now.hour >= 22) {
      // 22:00 is 10 PM
      return DateUtils.dateOnly(now.add(const Duration(days: 1)));
    }
    return DateUtils.dateOnly(now);
  }

  void _initializeTabController() {
    _tabController ??= TabController(length: 2, vsync: this);
  }

  @override
  void initState() {
    super.initState();
    // --- MODIFIED: Initialize _selectedDate here ---
    _selectedDate = _getInitialDate();
    _initializeTabController();
    _searchController.addListener(_filterBookings);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          // It now fetches using the correct initial date
          .fetchMealListForDate(_selectedDate)
          .then((_) {
        _filterBookings();
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.removeListener(_filterBookings);
    _searchController.dispose();
    super.dispose();
  }

  void _filterBookings() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final mealList = adminProvider.mealList;
    final query = _searchController.text.toLowerCase();

    if (mealList == null) {
      if (mounted) setState(() => _filteredBookings = []);
      return;
    }

    if (query.isEmpty) {
      if (mounted) setState(() => _filteredBookings = mealList.bookings);
      return;
    }

    if (mounted) {
      setState(() {
        _filteredBookings = mealList.bookings.where((booking) {
          final nameMatches = booking.userName.toLowerCase().contains(query);
          final roomMatches = booking.roomNumber.toString().contains(query);
          return nameMatches || roomMatches;
        }).toList();
      });
    }
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
      await Provider.of<AdminProvider>(context, listen: false)
          .fetchMealListForDate(picked);
      _filterBookings();
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
      final Uint8List pdfBytes = await PdfExportService.generateMealListPdf(
        adminProvider.mealList!,
      );

      final dateString =
          DateFormat('yyyy-MM-dd').format(adminProvider.mealList!.bookingDate);
      final pdfName = 'MealList_$dateString.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: pdfName);
      } else {
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
    _initializeTabController();
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

                return Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.dashboard_rounded, size: 20),
                              SizedBox(width: 8),
                              Text("Summary"),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.list_alt_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  "Student List (${_filteredBookings.length})"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryTab(theme, mealList),
                          _buildStudentListTab(theme),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ThemeData theme, MealList mealList) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 80.0),
      children: [
        _buildSummaryCard(mealList),
        _buildItemChart(
          theme,
          "Lunch Breakdown",
          Icons.wb_sunny_rounded,
          Colors.orange,
          mealList.lunchItemCounts,
        ),
        _buildItemChart(
          theme,
          "Dinner Breakdown",
          Icons.nights_stay_rounded,
          Colors.indigo,
          mealList.dinnerItemCounts,
        ),
      ],
    );
  }

  Widget _buildStudentListTab(ThemeData theme) {
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: _filteredBookings.isEmpty
              ? Center(
                  child: _searchController.text.isNotEmpty
                      ? const Text("No students found.")
                      : const Text("No students have booked for this date."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 80.0),
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 4.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(
                          booking.userName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Room ${booking.roomNumber}",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 12),
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or room...',
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

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

  Widget _buildItemChart(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    Map<String, dynamic> items,
  ) {
    final sortedEntries = items.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${items.length} items',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        children: [
          Container(
            color: theme.cardTheme.color,
            padding: const EdgeInsets.all(16.0),
            child: items.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(child: Text('No items for this meal')))
                : Column(
                    children: sortedEntries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: theme.textTheme.bodyLarge),
                            Text(
                              entry.value.toString(),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
}
