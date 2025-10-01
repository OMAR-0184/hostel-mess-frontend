// provider/booking_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _error;

  // New properties for fetching today's booking status
  Map<String, dynamic>? _todaysBooking;
  bool _isLoadingTodaysBooking = false;
  bool _hasFetchedTodaysBooking = false;

  // Getters for the original state
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // Getters for the new state
  Map<String, dynamic>? get todaysBooking => _todaysBooking;
  bool get isLoadingTodaysBooking => _isLoadingTodaysBooking;

  /// Submits a new meal booking or updates an existing one for a specific date.
  /// Corresponds to the POST /bookings/ endpoint.
  Future<bool> submitBooking({
    required DateTime date,
    required List<String> lunchPicks,
    required List<String> dinnerPicks,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.post('/bookings/', {
        'booking_date': dateString,
        'lunch_pick': lunchPicks,
        'dinner_pick': dinnerPicks,
      });

      if (response.statusCode == 201) {
        _isSubmitting = false;
        if (DateUtils.isSameDay(date, DateTime.now())) {
          await fetchTodaysBooking(forceRefresh: true);
        }
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to submit booking.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  /// Cancels a booking for a specific date.
  /// Corresponds to the DELETE /bookings/{booking_date} endpoint.
  Future<bool> cancelBooking(DateTime date) async {
     final dateString = DateFormat('yyyy-MM-dd').format(date);
     try {
       final response = await _apiService.delete('/bookings/$dateString');
       if (response.statusCode == 204) {
         if (DateUtils.isSameDay(date, DateTime.now())) {
           await fetchTodaysBooking(forceRefresh: true);
         }
         return true;
       }
       return false;
     } catch (e) {
       print(e);
       return false;
     }
  }

  /// Fetches the current user's meal booking for today.
  /// Required for the dashboard screen.
  /// Corresponds to the GET /meallist/me/today endpoint.
  Future<void> fetchTodaysBooking({bool forceRefresh = false}) async {
    if (_hasFetchedTodaysBooking && !forceRefresh) return;

    _isLoadingTodaysBooking = true;
    // Don't clear previous data instantly for a smoother UI
    // _todaysBooking = null; 
    notifyListeners();
    
    try {
      final response = await _apiService.get('/meallist/me/today');
      if (response.statusCode == 200) {
        _todaysBooking = json.decode(response.body);
      } else {
        _todaysBooking = null;
      }
      _hasFetchedTodaysBooking = true; // Mark as fetched even on failure to prevent repeated calls
    } catch (e) {
      print("Error fetching today's booking: $e");
      _todaysBooking = null;
    }
    
    _isLoadingTodaysBooking = false;
    notifyListeners();
  }
}