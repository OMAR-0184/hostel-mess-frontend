// lib/provider/menu_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class DailyMenu {
  final DateTime menuDate;
  final List<String> lunchOptions;
  final List<String> dinnerOptions;

  DailyMenu({required this.menuDate, required this.lunchOptions, required this.dinnerOptions});

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      menuDate: DateTime.parse(json['menu_date']),
      lunchOptions: List<String>.from(json['lunch_options']),
      dinnerOptions: List<String>.from(json['dinner_options']),
    );
  }
}

class MenuProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  DailyMenu? _menu;
  bool _isLoading = false;
  String? _error;

  // Caching map
  final Map<DateTime, DailyMenu> _menuCache = {};

  DailyMenu? get menu => _menu;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMenuForDate(DateTime date, {bool forceRefresh = false}) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (_menuCache.containsKey(dateOnly) && !forceRefresh) {
      _menu = _menuCache[dateOnly];
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _menu = null;
    notifyListeners();

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.get('/menus/$dateString');
      if (response.statusCode == 200) {
        _menu = DailyMenu.fromJson(json.decode(response.body));
        _menuCache[dateOnly] = _menu!;
      } else if (response.statusCode == 404) {
        _error = 'No menu has been set for this date.';
      } else {
        _error = 'Failed to load menu. Please try again.';
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Helper to clear menu for a date from cache
  void clearMenuForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    _menuCache.remove(dateOnly);
    if (_menu != null && DateUtils.isSameDay(_menu!.menuDate, dateOnly)) {
      _menu = null;
    }
    notifyListeners();
  }
}