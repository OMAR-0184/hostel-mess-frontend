// provider/my_bookings_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class BookingHistoryItem {
  final DateTime bookingDate;
  final List<String>? lunchPick;
  final List<String>? dinnerPick;

  BookingHistoryItem({
    required this.bookingDate,
    this.lunchPick,
    this.dinnerPick,
  });

  factory BookingHistoryItem.fromJson(Map<String, dynamic> json) {
    return BookingHistoryItem(
      bookingDate: DateTime.parse(json['booking_date']),
      lunchPick: json['lunch_pick'] != null ? List<String>.from(json['lunch_pick']) : null,
      dinnerPick: json['dinner_pick'] != null ? List<String>.from(json['dinner_pick']) : null,
    );
  }
}

class MyBookingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<BookingHistoryItem> _bookingHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingHistoryItem> get bookingHistory => _bookingHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookingHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/bookings/me');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _bookingHistory = responseData.map((data) => BookingHistoryItem.fromJson(data)).toList();
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to load booking history.';
        _bookingHistory = []; // Clear old data on error
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}
