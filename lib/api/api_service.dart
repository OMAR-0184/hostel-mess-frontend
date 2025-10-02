// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = "https://hostel-mess-backend.onrender.com";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

   Future<Map<String, String>> _getHeaders({String? temporaryToken}) async {
    final storedToken = await _getToken();
    final token = temporaryToken ?? storedToken; // Use the temporary token if it exists

    return {
      // FIX: Corrected the typo from 'UTF--8' to 'UTF-8'
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
 Future<http.Response> get(String endpoint, {String? temporaryToken}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(temporaryToken: temporaryToken);
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return http.post(url, headers: headers, body: json.encode(body));
  }
  
  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return http.patch(url, headers: headers, body: json.encode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return http.delete(url, headers: headers);
  }

  // Special post method for login which uses x-www-form-urlencoded
  Future<http.Response> postUrlEncoded(String endpoint, Map<String, String> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
  }
}