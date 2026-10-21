import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../models/product.dart';
import 'auth_service.dart';

// Loi API kem ma HTTP (401: chua dang nhap/het han, 403: khong co quyen).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ProductService {
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

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse(ConfigUrl.products),
      headers: await _headers(),
    );
    if (response.statusCode == 401) {
      throw ApiException(401, 'Phiên đăng nhập hết hạn');
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Không có quyền');
    }
    if (response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Lỗi tải sản phẩm: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  // Admin: PUT ca san pham (dung de doi categoryId, null = khong co danh muc).
  Future<void> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('${ConfigUrl.products}/${product.id}'),
      headers: await _headers(),
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 401) {
      throw ApiException(401, 'Phiên đăng nhập hết hạn');
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Không có quyền');
    }
    if (response.statusCode == 400) {
      throw ApiException(400, _readMessage(response.body, 'Dữ liệu không hợp lệ'));
    }
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Lỗi sửa sản phẩm: ${response.statusCode}');
    }
  }

  // Admin: POST san pham moi (id = 0, server tu sinh id).
  Future<void> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse(ConfigUrl.products),
      headers: await _headers(),
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 401) {
      throw ApiException(401, 'Phiên đăng nhập hết hạn');
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Không có quyền');
    }
    if (response.statusCode == 400) {
      throw ApiException(400, _readMessage(response.body, 'Dữ liệu không hợp lệ'));
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Lỗi thêm sản phẩm: ${response.statusCode}');
    }
  }

  // Loi 400: { message } (vd "Danh muc khong ton tai")
  // hoac { errors: { Price: [...] } } (loi [Range] cua ASP.NET).
  String _readMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data['message'] != null) return data['message'];
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values.expand((e) => e as List).join('\n');
      }
    } catch (_) {}
    return fallback;
  }
}
