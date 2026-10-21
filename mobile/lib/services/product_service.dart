import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse(ConfigUrl.products));
    if (response.statusCode != 200) {
      throw Exception('Lỗi tải sản phẩm: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }
}
