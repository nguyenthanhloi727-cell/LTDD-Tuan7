import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/logout_button.dart';

// Trang User: danh sach san pham.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _productService = ProductService();
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _productService.getProducts();
  }

  Future<void> _reload() async {
    setState(() {
      _futureProducts = _productService.getProducts();
    });
    await _futureProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm'),
        actions: const [LogoutButton()],
      ),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(p.name),
                  subtitle: Text(p.description ?? ''),
                  trailing: Text('${p.price.toStringAsFixed(0)} đ'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
