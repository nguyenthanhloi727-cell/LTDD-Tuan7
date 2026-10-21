import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';

class AuthService {
  static const String tokenKey = 'token';
  // ASP.NET dung ClaimTypes.Role -> ten claim dai trong JWT
  static const String roleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  // Goi API login, thanh cong thi luu token. Tra ve null neu ok, nguoc lai la thong bao loi.
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ConfigUrl.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return null;
    }
    return _readError(response, 'Đăng nhập thất bại');
  }

  // Goi API register. Tra ve null neu ok, nguoc lai la thong bao loi.
  Future<String?> register(String username, String email, String password,
      String initials) async {
    final response = await http.post(
      Uri.parse(ConfigUrl.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'initials': initials,
        'role': 'User',
      }),
    );
    if (response.statusCode == 200) return null;
    return _readError(response, 'Đăng ký thất bại');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Token con han thi tra ve token, het han hoac chua co thi tra ve null
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || JwtDecoder.isExpired(token)) return null;
    return token;
  }

  // Lay role tu token (claim role co the la chuoi hoac mang).
  // Co "Admin" thi tra "Admin", con lai tra "User".
  String getRole(String token) {
    final decoded = JwtDecoder.decode(token);
    debugPrint('JWT payload: $decoded'); // TODO xoa truoc khi nop
    final role = decoded[roleClaim] ?? decoded['role'];
    final roles = role is List ? role : [role];
    return roles.contains('Admin') ? 'Admin' : 'User';
  }

  String _readError(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e['description']).join('\n');
      }
      return data['message'] ?? fallback;
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }
  }
}
