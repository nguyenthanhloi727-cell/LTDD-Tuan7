import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';

// Goi API dang nhap/dang ky va luu token JWT vao SharedPreferences.
class AuthService {
  static const String tokenKey = 'token';

  // Key claim role ma ASP.NET Core (ClaimTypes.Role) ghi vao token
  static const String roleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  // Tra ve null neu thanh cong, nguoc lai tra ve thong bao loi
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ConfigUrl.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) {
      return _message(response, 'Đăng nhập thất bại');
    }
    final data = jsonDecode(response.body);
    await saveToken(data['token']);
    return null;
  }

  Future<String?> register(
      String username, String email, String password, String initials) async {
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
    if (response.statusCode != 200) {
      return _message(response, 'Đăng ký thất bại');
    }
    return null;
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

  // Token con han thi tra ve token, het han/khong co thi tra ve null
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || JwtDecoder.isExpired(token)) return null;
    return token;
  }

  // Role co the la chuoi (1 role) hoac mang (nhieu role)
  String getRole(String token) {
    final role = JwtDecoder.decode(token)[roleClaim];
    if (role is List) return role.isNotEmpty ? role.first.toString() : 'User';
    return role?.toString() ?? 'User';
  }

  String _message(http.Response response, String fallback) {
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
