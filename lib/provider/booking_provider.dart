// lib/provider/booking_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart'; // FIX: Corrected import path
import 'package:intl/intl.dart'; // FIX: Corrected import path
import '../api/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _error;

  // Properties for today's booking status (for dashboard)
  Map<String, dynamic>? _todaysBooking;
  bool _isLoadingTodaysBooking = false;
  bool _hasFetchedTodaysBooking = false;

  // --- NEW: Properties for managing booking on any selected date ---
  Map<String, dynamic>? _selectedDateBooking;
  bool _isLoadingSelectedDateBooking = false;
  final Map<DateTime, Map<String, dynamic>?> _bookingCache = {};


  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic>? get todaysBooking => _todaysBooking;
  bool get isLoadingTodaysBooking => _isLoadingTodaysBooking;
  Map<String, dynamic>? get selectedDateBooking => _selectedDateBooking;
  bool get isLoadingSelectedDateBooking => _isLoadingSelectedDateBooking;


  /// Submits a new meal booking or updates an existing one for a specific date.
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
      // API endpoint for booking is assumed to handle both create and update (PUT or POST)
      final response = await _apiService.post('/bookings/', {
        'booking_date': dateString,
        'lunch_pick': lunchPicks,
        'dinner_pick': dinnerPicks,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isSubmitting = false;
        // Refresh data for the affected date
        await fetchBookingForDate(date, forceRefresh: true);
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
      debugPrint(e.toString());
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  /// Cancels a booking for a specific date.
  Future<bool> cancelBooking(DateTime date) async {
     final dateString = DateFormat('yyyy-MM-dd').format(date);
     try {
       // FIX: Removed the trailing slash from the endpoint
       final response = await _apiService.delete('/bookings/$dateString');
       if (response.statusCode == 204) {
         // Refresh data for the affected date
         await fetchBookingForDate(date, forceRefresh: true);
         if (DateUtils.isSameDay(date, DateTime.now())) {
           await fetchTodaysBooking(forceRefresh: true);
         }
         return true;
       }
       return false;
     } catch (e) {
       debugPrint(e.toString());
       return false;
     }
  }

  /// --- NEW: Fetches the booking for a specific date with caching ---
  Future<void> fetchBookingForDate(DateTime date, {bool forceRefresh = false}) async {
    final dateOnly = DateUtils.dateOnly(date);
    if (_bookingCache.containsKey(dateOnly) && !forceRefresh) {
      if(_selectedDateBooking != _bookingCache[dateOnly]) {
         _selectedDateBooking = _bookingCache[dateOnly];
         notifyListeners();
      }
      return;
    }

    _isLoadingSelectedDateBooking = true;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.get('/bookings/$dateString/');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _selectedDateBooking = data;
        _bookingCache[dateOnly] = data;
      } else {
        // A 404 is not an error, it just means no booking exists.
        _selectedDateBooking = null;
        _bookingCache[dateOnly] = null;
      }
    } catch (e) {
      _selectedDateBooking = null;
      // Don't cache on error, so we can retry
      debugPrint("Error fetching booking for date $dateString: $e");
    }

    _isLoadingSelectedDateBooking = false;
    notifyListeners();
  }


  /// Fetches the current user's meal booking for today (for dashboard).
  Future<void> fetchTodaysBooking({bool forceRefresh = false}) async {
    if (_hasFetchedTodaysBooking && !forceRefresh) return;

    _isLoadingTodaysBooking = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/meallist/me/today');
      if (response.statusCode == 200) {
        _todaysBooking = json.decode(response.body);
      } else {
        _todaysBooking = null;
      }
      _hasFetchedTodaysBooking = true;
    } catch (e) {
      debugPrint("Error fetching today's booking: $e");
      _todaysBooking = null;
    }

    _isLoadingTodaysBooking = false;
    notifyListeners();
  }
}