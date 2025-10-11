// lib/provider/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isAuthenticated => _token != null && _currentUser != null;
  User? get user => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token');
      await fetchCurrentUser();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      final response = await _apiService.postUrlEncoded('/auth/login', {
        'username': email,
        'password': password,
      });
      print('Login StatusCode : ${response.statusCode}');
      print('Login Response Body : ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['access_token'];
         await fetchCurrentUser(temporaryToken: _token);

        if (_currentUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          notifyListeners();
          return true;
        }
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'An unknown error occurred on the server.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to the server. Please check your connection.';
      print("A network or other error occurred: $e");
    }
    return false;
  }
  Future<void> fetchCurrentUser({String? temporaryToken}) async {
    try {
      final response = await _apiService.get('/auth/me', temporaryToken: temporaryToken);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _currentUser = User.fromJson(responseData);
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      print("Error fetching current user: $e");
    }
    notifyListeners();
  }


  Future<bool> register(String name, String email, String password, int roomNumber) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'room_number': roomNumber,
      });
      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _errorMessage = null;
    try {
      final response = await _apiService.post('/auth/forgot-password', {'email': email});
      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'An unknown error occurred.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to the server.';
      print(e);
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _errorMessage = null;
    try {
      final response = await _apiService.post('/auth/reset-password', {
        'token': token,
        'new_password': newPassword,
      });
      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['detail'] ?? 'An unknown error occurred.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to the server.';
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}