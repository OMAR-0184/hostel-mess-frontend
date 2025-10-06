// lib/provider/admin_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/user.dart';


class MealListItem {
  final String userName;
  final int roomNumber;
  final List<String> lunchPick;
  final List<String> dinnerPick;

  MealListItem({
    required this.userName,
    required this.roomNumber,
    required this.lunchPick,
    required this.dinnerPick,
  });

  factory MealListItem.fromJson(Map<String, dynamic> json) {
    return MealListItem(
      userName: json['user_name'],
      roomNumber: json['room_number'],
      lunchPick: List<String>.from(json['lunch_pick'] ?? []),
      dinnerPick: List<String>.from(json['dinner_pick'] ?? []),
    );
  }
}


class MealList {
  final DateTime bookingDate;
  final int totalLunchBookings;
  final int totalDinnerBookings;
  final Map<String, dynamic> lunchItemCounts;
  final Map<String, dynamic> dinnerItemCounts;
  final List<MealListItem> bookings;

  MealList({
    required this.bookingDate,
    required this.totalLunchBookings,
    required this.totalDinnerBookings,
    required this.lunchItemCounts,
    required this.dinnerItemCounts,
    required this.bookings,
  });

  factory MealList.fromJson(Map<String, dynamic> json) {
    return MealList(
      bookingDate: DateTime.parse(json['booking_date']),
      totalLunchBookings: json['total_lunch_bookings'],
      totalDinnerBookings: json['total_dinner_bookings'],
      lunchItemCounts: json['lunch_item_counts'],
      dinnerItemCounts: json['dinner_item_counts'],
      bookings: json['bookings'] != null
          ? (json['bookings'] as List)
              .map((i) => MealListItem.fromJson(i))
              .toList()
          : [],
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
    _isLoading = true;
    _error = null;
    _mealList = null;
    notifyListeners();
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await _apiService.get('/meallist/$dateString');
      if (response.statusCode == 200) {
        _mealList = MealList.fromJson(json.decode(response.body));
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

  /// Sets the daily menu by calling POST /menus/
  Future<bool> setDailyMenu({
    required DateTime date,
    required List<String> lunchOptions,
    required List<String> dinnerOptions,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/menus/', {
        'menu_date': DateFormat('yyyy-MM-dd').format(date),
        'lunch_options': lunchOptions,
        'dinner_options': dinnerOptions,
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
  
  /// Deletes the daily menu by calling DELETE /menus/{date}
  Future<bool> deleteMenuForDate(DateTime date) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.delete('/menus/$dateString');

      if (response.statusCode == 204) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to delete menu.';
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

  Future<bool> updateUserRole(int userId, String newRole) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch('/users/$userId', {'role': newRole});

      if (response.statusCode == 200) {
        await fetchAllUsers(forceRefresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to update role.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteUser(int userId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/users/$userId');

      if (response.statusCode == 204) {
        await fetchAllUsers(forceRefresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to delete user.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  // NEW METHOD
  Future<bool> updateUserMessStatus(int userId, bool isMessActive) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch('/users/$userId/mess-status', {'is_mess_active': isMessActive});

      if (response.statusCode == 200) {
        await fetchAllUsers(forceRefresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['detail'] ?? 'Failed to update mess status.';
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