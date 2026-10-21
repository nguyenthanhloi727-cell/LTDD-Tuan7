import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../models/category.dart';
import 'auth_service.dart';
import 'product_service.dart' show ApiException;

class CategoryService {
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

  // 401: het han dang nhap, 403: khong phai Admin.
  void _check(http.Response response, String action) {
    if (response.statusCode == 401) {
      throw ApiException(401, 'Phiên đăng nhập hết hạn');
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Không có quyền');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          response.statusCode, 'Lỗi $action: ${response.statusCode}');
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse(ConfigUrl.categories),
      headers: await _headers(),
    );
    _check(response, 'tải danh mục');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<void> createCategory(String name) async {
    final response = await http.post(
      Uri.parse(ConfigUrl.categories),
      headers: await _headers(),
      body: jsonEncode({'name': name}),
    );
    _check(response, 'thêm danh mục');
  }

  Future<void> updateCategory(Category category) async {
    final response = await http.put(
      Uri.parse('${ConfigUrl.categories}/${category.id}'),
      headers: await _headers(),
      body: jsonEncode(category.toJson()),
    );
    _check(response, 'sửa danh mục');
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('${ConfigUrl.categories}/$id'),
      headers: await _headers(),
    );
    _check(response, 'xóa danh mục');
  }
}
