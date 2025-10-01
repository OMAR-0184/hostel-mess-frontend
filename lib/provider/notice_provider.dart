// lib/provider/notice_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class Notice {
  final String title;
  final String content;
  final DateTime createdAt;

  Notice({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NoticeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Caching flag
  bool _hasFetched = false;

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotices({bool forceRefresh = false}) async {
    if (_hasFetched && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/notices/');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _notices = responseData.map((data) => Notice.fromJson(data)).toList();
        _hasFetched = true; // Mark as fetched
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to load notices.';
        _notices = []; // Clear old data on error
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}