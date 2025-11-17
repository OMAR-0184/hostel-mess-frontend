// lib/provider/booking_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _error;

  // Properties for today's booking status (for dashboard)
  Map<String, dynamic>? _todaysBooking;
  bool _isLoadingTodaysBooking = false;
  bool _hasFetchedTodaysBooking = false;

  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic>? get todaysBooking => _todaysBooking;
  bool get isLoadingTodaysBooking => _isLoadingTodaysBooking;

  /// Submits a new meal booking or updates an existing one for a specific date.
  /// (This is the original "upsert" function)
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
      // API endpoint for booking handles both create (201) and update (200)
      final response = await _apiService.post('/bookings/', {
        'booking_date': dateString,
        'lunch_pick': lunchPicks,
        'dinner_pick': dinnerPicks,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isSubmitting = false;
        // Refresh data for today's booking if it was affected
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

  // --- NEW FUNCTION ADDED ---
  /// Updates ONLY the lunch pick for a specific date.
  Future<bool> updateLunchBooking(
      DateTime date, List<String> lunchPicks) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.patch('/bookings/update-lunch', {
        'booking_date': dateString,
        'lunch_pick': lunchPicks,
      });

      if (response.statusCode == 200) {
        _isSubmitting = false;
        if (DateUtils.isSameDay(date, DateTime.now())) {
          await fetchTodaysBooking(forceRefresh: true);
        }
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to update lunch.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      debugPrint(e.toString());
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  // --- NEW FUNCTION ADDED ---
  /// Updates ONLY the dinner pick for a specific date.
  Future<bool> updateDinnerBooking(
      DateTime date, List<String> dinnerPicks) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.patch('/bookings/update-dinner', {
        'booking_date': dateString,
        'dinner_pick': dinnerPicks,
      });

      if (response.statusCode == 200) {
        _isSubmitting = false;
        if (DateUtils.isSameDay(date, DateTime.now())) {
          await fetchTodaysBooking(forceRefresh: true);
        }
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to update dinner.';
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
      final response = await _apiService.delete('/bookings/$dateString');
      if (response.statusCode == 204) {
        // Refresh data for today's booking if it was affected
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
