import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class Notice {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  Notice({required this.id, required this.title, required this.content, required this.createdAt});

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
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

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;

  Future<void> fetchNotices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/notices/');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _notices = responseData.map((data) => Notice.fromJson(data)).toList();
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }
}
