// lib/provider/admin_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/user.dart';


class MealList {
  final DateTime bookingDate;
  final int totalLunchBookings;
  final int totalDinnerBookings;
  final Map<String, dynamic> lunchItemCounts;
  final Map<String, dynamic> dinnerItemCounts;

  MealList({
    required this.bookingDate,
    required this.totalLunchBookings,
    required this.totalDinnerBookings,
    required this.lunchItemCounts,
    required this.dinnerItemCounts,
  });

  factory MealList.fromJson(Map<String, dynamic> json) {
    return MealList(
      bookingDate: DateTime.parse(json['booking_date']),
      totalLunchBookings: json['total_lunch_bookings'],
      totalDinnerBookings: json['total_dinner_bookings'],
      lunchItemCounts: json['lunch_item_counts'],
      dinnerItemCounts: json['dinner_item_counts'],
    );
  }
}

// Manages state and API calls for admin-related features
class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  MealList? _mealList;
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;

  // Caching flags
  bool _hasFetchedUsers = false;
  final Map<DateTime, MealList> _mealListCache = {};

  // Public getters to access the state
  List<User> get users => _users;
  MealList? get mealList => _mealList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;

  /// Fetches the list of all users from the /users/ endpoint.
  Future<void> fetchAllUsers({bool forceRefresh = false}) async {
    if (_hasFetchedUsers && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/users/');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _users = responseData.map((data) => User.fromJson(data)).toList();
        _hasFetchedUsers = true; // Mark as fetched
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMealListForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (_mealListCache.containsKey(dateOnly)) {
      _mealList = _mealListCache[dateOnly];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _mealList = null;
    notifyListeners();
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await _apiService.get('/meallist/$dateString');
      if (response.statusCode == 200) {
        _mealList = MealList.fromJson(json.decode(response.body));
        _mealListCache[dateOnly] = _mealList!; // Cache the result
      } else {
        _error = "No bookings found for this date.";
      }
    } catch (e) {
      _error = "An error occurred fetching the meal list.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Sets the daily menu by calling POST /menus
  Future<bool> setDailyMenu({required DateTime date, required String lunchOptions, required String dinnerOptions}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    // Convert multiline strings to lists of strings
    final lunchList = lunchOptions.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final dinnerList = dinnerOptions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    try {
      final response = await _apiService.post('/menus/', {
        'menu_date': DateFormat('yyyy-MM-dd').format(date),
        'lunch_options': lunchList,
        'dinner_options': dinnerList,
      });

      if (response.statusCode == 201) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to set menu.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  /// Posts a new notice by calling POST /notices/
  Future<bool> postNotice({required String title, required String content}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/notices/', {
        'title': title,
        'content': content,
      });

      if (response.statusCode == 201) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to post notice.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }
    
    _isSubmitting = false;
    notifyListeners();
    return false;
  }
}