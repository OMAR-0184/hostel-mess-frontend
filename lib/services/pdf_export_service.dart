// lib/services/pdf_export_service.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // <-- THIS IS THE FIX (was 'package://')
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../provider/admin_provider.dart';
import 'package:printing/printing.dart';

class PdfExportService {
  // --- DESIGN CONSTANTS ---
  static const PdfColor primaryColor = PdfColors.indigo;
  static const PdfColor accentColor = PdfColors.orange;
  static const PdfColor lightGrey = PdfColors.grey200;
  static const PdfColor darkGrey = PdfColors.grey700;

  // --- MODIFIED FUNCTION SIGNATURE ---
  // Removed lunchChartImage and dinnerChartImage parameters
  static Future<Uint8List> generateMealListPdf(
    MealList mealList,
  ) async {
    final doc = pw.Document();
    final poppinsFont = await PdfGoogleFonts.poppinsRegular();
    final poppinsBold = await PdfGoogleFonts.poppinsBold();

    final imageStyle = pw.ThemeData.withFont(
      base: poppinsFont,
      bold: poppinsBold,
    );
    
    // --- REMOVED chart image creation ---

    doc.addPage(
      pw.MultiPage(
        // Tighter margins to save paper
        margin: const pw.EdgeInsets.symmetric(
            horizontal: 2.0 * PdfPageFormat.cm,
            vertical: 1.5 * PdfPageFormat.cm),
        pageFormat: PdfPageFormat.a4,
        header: null, // No repeating header
        footer: (context) => _buildFooter(context, poppinsFont),
        build: (context) => [
          // 1. Header (Only on first page)
          _buildHeader(mealList, poppinsBold),
          pw.SizedBox(height: 20),

          // 2. Summary
          _buildSummary(mealList, poppinsBold, poppinsFont),
          pw.SizedBox(height: 20),
          
          // 3. --- REMOVED CHARTS ---

          // 4. Item Counts Table
          _buildItemCountsTable(mealList, poppinsBold, poppinsFont),
          pw.SizedBox(height: 20),

          // 5. Student Table
          pw.Text('Student Bookings (${mealList.bookings.length} Students)',
              style: pw.TextStyle(
                  font: poppinsBold, fontSize: 18, color: primaryColor)),
          pw.Divider(color: lightGrey, thickness: 1),
          pw.SizedBox(height: 10),
          _buildStudentTable(mealList, poppinsBold, poppinsFont),
        ],
      ),
    );

    return await doc.save();
  }

  // --- PDF WIDGETS ---

  static pw.Widget _buildHeader(MealList mealList, pw.Font boldFont) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'Daily Meal List',
            style: pw.TextStyle(
                font: boldFont, fontSize: 24, color: primaryColor),
          ),
          pw.Text(
            DateFormat('EEEE, d MMMM yyyy').format(mealList.bookingDate),
            style: pw.TextStyle(fontSize: 18, color: darkGrey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(
      MealList mealList, pw.Font boldFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Total Bookings',
            style: pw.TextStyle(
                font: boldFont, fontSize: 14, color: primaryColor)),
        pw.Divider(color: lightGrey),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryBox('Total Lunch',
                  mealList.totalLunchBookings.toString(), accentColor, boldFont, regularFont),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _buildSummaryBox('Total Dinner',
                  mealList.totalDinnerBookings.toString(), primaryColor, boldFont, regularFont),
            ),
          ]
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String title, String value, PdfColor color,
      pw.Font boldFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 32, color: color),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            title,
            style: pw.TextStyle(
                font: regularFont, fontSize: 14, color: darkGrey),
          ),
        ],
      ),
    );
  }

  // --- DELETED _buildCharts widget ---

  static pw.Widget _buildItemCountsTable(
      MealList mealList, pw.Font boldFont, pw.Font regularFont) {
    final lunchData = mealList.lunchItemCounts.entries
        .map((e) => [e.key, e.value.toString()])
        .toList();

    final dinnerData = mealList.dinnerItemCounts.entries
        .map((e) => [e.key, e.value.toString()])
        .toList();

    final tableStyle = pw.TextStyle(font: regularFont, fontSize: 9);
    final headerStyle =
        pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Item Counts (Data)',
            style: pw.TextStyle(
                font: boldFont, fontSize: 14, color: primaryColor)),
        pw.Divider(color: lightGrey),
        pw.SizedBox(height: 5),
        pw.Table.fromTextArray(
            headers: ['Lunch Item', 'Count'],
            data: lunchData,
            headerStyle: headerStyle,
            cellStyle: tableStyle,
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
            headerDecoration: pw.BoxDecoration(color: accentColor),
            border: pw.TableBorder.all(color: lightGrey),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            }),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
            headers: ['Dinner Item', 'Count'],
            data: dinnerData,
            headerStyle: headerStyle,
            cellStyle: tableStyle,
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            border: pw.TableBorder.all(color: lightGrey),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            }),
      ],
    );
  }

  static pw.Widget _buildStudentTable(
      MealList mealList, pw.Font boldFont, pw.Font regularFont) {
    final headers = ['Room', 'Student Name', 'Lunch Picks', 'Dinner Picks'];
    final data = mealList.bookings.map((booking) {
      return [
        booking.roomNumber.toString(),
        booking.userName,
        booking.lunchPick.join(', '),
        booking.dinnerPick.join(', '),
      ];
    }).toList();

    // Sort by Room Number (as a number)
    data.sort((a, b) => int.parse(a[0]).compareTo(int.parse(b[0])));

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: lightGrey),
      // Compact styles to save space
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: lightGrey),
      cellPadding: const pw.EdgeInsets.all(4),
      cellStyle: pw.TextStyle(font: regularFont, fontSize: 9),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Room No
        1: const pw.FlexColumnWidth(3), // Name
        2: const pw.FlexColumnWidth(2.5), // Lunch
        3: const pw.FlexColumnWidth(2.5), // Dinner
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(font: font, color: darkGrey, fontSize: 9),
      ),
    );
  }

}