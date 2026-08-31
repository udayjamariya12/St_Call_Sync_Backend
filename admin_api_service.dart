import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic> errors;
  ValidationException(this.message, this.errors);

  @override
  String toString() => message;
}

class AdminApiService {
  static const String baseUrl = 'http://10.253.222.116:8000/api';
  static const String tokenKey = 'admin_auth_token';

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API responses and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final message = errorBody['message'] ?? 'An error occurred';
      
      if (response.statusCode == 422 && errorBody['errors'] != null) {
        throw ValidationException(message, errorBody['errors']);
      }
      
      throw Exception(message);
    }
  }

  // 1. Login
  Future<Map<String, dynamic>> login(String mobileNumber, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'mobileNumber': mobileNumber,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    
    // Check if user is admin (only if backend returns user object)
    final user = data['user'];
    if (user != null && user['role'] != 'admin') {
      throw Exception('Unauthorized: Admin access required.');
    }

    // Save token (Laravel usually returns access_token)
    final token = data['token'] ?? data['access_token'];
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
    } else {
      throw Exception('Failed to retrieve token from server.');
    }

    return data;
  }

  // 2. Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard-stats'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }

  // 3. Users List
  Future<List<dynamic>> getUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: headers,
    );
    
    final data = _handleResponse(response);
    // Depending on the exact Laravel response format, it might be wrapped in 'data' or similar. 
    // Assuming it returns the list directly or inside a 'data' key.
    if (data is List) return data;
    return data['data'] ?? [];
  }

  // 4. Call Logs List
  Future<Map<String, dynamic>> getCallLogs({int page = 1}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/calls?page=$page'),
      headers: headers,
    );
    
    final data = _handleResponse(response);
    // Returns paginated call logs
    return data;
  }
  
  // Logout function
  Future<void> logout() async {
    // Optional: Call backend logout API here if needed
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );
    } catch (e) {
      // Ignore if it fails, just clear local token
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // --- User Management CRUD ---

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<void> deleteUser(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
    );
    _handleResponse(response);
  }

  Future<void> resetUserPassword(int id, String newPassword) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/users/$id/reset-password'),
      headers: headers,
      body: jsonEncode({'password': newPassword}),
    );
    _handleResponse(response);
  }
}
