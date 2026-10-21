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
  // Header co token: Authorization: Bearer <token>
  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Lỗi sửa sản phẩm: ${response.statusCode}');
    }
  }
}
