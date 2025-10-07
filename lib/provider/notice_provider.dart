// lib/provider/notice_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class Notice {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String author;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      author: json['name'] ?? 'Admin', // UPDATED: Changed 'author_name' to 'name' to match API
    );
  }
}

class NoticeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDeleting = false;

  bool _hasFetched = false;

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDeleting => _isDeleting;

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
        _hasFetched = true;
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to load notices.';
        _notices = [];
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteNotice(int noticeId) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/notices/$noticeId');
      if (response.statusCode == 204) {
        await fetchNotices(forceRefresh: true);
        _isDeleting = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to delete notice.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please check your connection.';
      print(e);
    }

    _isDeleting = false;
    notifyListeners();
    return false;
  }
}