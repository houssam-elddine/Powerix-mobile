// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  final String baseUrl = 'http://10.0.2.2:8000/api'; // غيّر إذا لزم الأمر

  bool get isAuthenticated => _token != null;
  String? get role => _user?['role'];
  int? get userId => _user?['id'] as int?;
  String? get token => _token;

  // ✅ إضافة getter عام للوصول إلى بيانات المستخدم
  Map<String, dynamic>? get user => _user;

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password
      }),
    );

    if (response.statusCode == 201) {
      await login(email, password);
    } else {
      final error = json.decode(response.body)['message'] ?? 'فشل التسجيل';
      throw Exception(error);
    }
  }

  Future<void> login(String email, String password) async {
    try{
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
      } else {
        final error = json.decode(response.body)['message'] ?? 'بيانات الدخول غير صحيحة';
        throw Exception(error);
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString()); // أو return false لو عايز
    }
  }

  void updateUser(Map<String, dynamic> newUserData) {
    _user = newUserData;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user', json.encode(_user));
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Authorization': 'Bearer $savedToken'},
        );
      } catch (e) {
        debugPrint('فشل تسجيل الخروج من السيرفر: $e');
      }
    }

    _token = null;
    _user = null;
    await prefs.clear();
    notifyListeners();
  }

  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (_token != null && userJson != null) {
      try {
        _user = json.decode(userJson);
      } catch (e) {
        _user = null;
      }
      notifyListeners();
    }
  }

  Future<http.Response> apiRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    if (_token == null) {
      throw Exception('غير مصرح: يرجى تسجيل الدخول');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
      ...?extraHeaders,
    };

    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(url, headers: headers, body: json.encode(body));
        case 'PUT':
          return await http.put(url, headers: headers, body: json.encode(body));
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw Exception('طريقة HTTP غير مدعومة: $method');
      }
    } catch (e) {
      throw Exception('فشل الاتصال: $e');
    }
  }
}