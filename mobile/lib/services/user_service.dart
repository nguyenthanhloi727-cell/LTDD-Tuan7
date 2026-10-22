import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'product_service.dart' show ApiException;

// Goi API Quan ly tai khoan (chi Admin).
class UserService {
  // Header co token: Authorization: Bearer <token>.
  // Token het han theo exp -> bao 401 luon, khong goi API.
  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getValidToken();
    if (token == null) throw ApiException(401, 'Phiên đăng nhập hết hạn');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 401: het han dang nhap, 403: khong phai Admin, 400: vd khoa tai khoan Admin.
  void _check(http.Response response, String action) {
    if (response.statusCode == 401) {
      throw ApiException(401, 'Phiên đăng nhập hết hạn');
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Không có quyền');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Lỗi $action: ${response.statusCode}';
      try {
        message = jsonDecode(response.body)['message'] ?? message;
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
  }

  Future<List<AppUser>> getUsers() async {
    final response = await http.get(
      Uri.parse(ConfigUrl.users),
      headers: await _headers(),
    );
    _check(response, 'tải tài khoản');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => AppUser.fromJson(e)).toList();
  }

  Future<void> lock(String id) async {
    final response = await http.post(
      Uri.parse('${ConfigUrl.users}/$id/lock'),
      headers: await _headers(),
    );
    _check(response, 'khóa tài khoản');
  }

  Future<void> unlock(String id) async {
    final response = await http.post(
      Uri.parse('${ConfigUrl.users}/$id/unlock'),
      headers: await _headers(),
    );
    _check(response, 'mở khóa tài khoản');
  }

  // Admin "Buoc dang xuat": moi token cu cua user do bi 401.
  Future<void> revoke(String id) async {
    final response = await http.post(
      Uri.parse('${ConfigUrl.users}/$id/revoke'),
      headers: await _headers(),
    );
    _check(response, 'buộc đăng xuất');
  }

  // UP15: Admin doi role (Manager / Employee / User). Doi xong token cu cua nguoi do bi 401.
  Future<void> changeRole(String id, String role) async {
    final response = await http.post(
      Uri.parse('${ConfigUrl.users}/$id/role'),
      headers: await _headers(),
      body: jsonEncode({'role': role}),
    );
    _check(response, 'đổi role');
  }

  // Tu thu hoi token cua minh (nut demo het han token).
  Future<void> revokeMe() async {
    final response = await http.post(
      Uri.parse('${ConfigUrl.users}/me/revoke'),
      headers: await _headers(),
    );
    _check(response, 'thu hồi token');
  }
}
