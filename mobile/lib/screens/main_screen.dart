import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../widgets/biometric_off_button.dart';
import '../widgets/logout_button.dart';
import '../widgets/product_image.dart';
import '../widgets/refresh_message.dart';
import '../widgets/stock_text.dart';
import '../utils/format.dart';
import 'product_detail_screen.dart';

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
    _futureProducts = _fetch();
  }

  // Goi API; 401 -> dang xuat ve LoginScreen, 403 -> bao "Khong co quyen".
  Future<List<Product>> _fetch() async {
    try {
      return await _productService.getProducts();
    } on ApiException catch (e) {
      if (!mounted) rethrow;
      if (e.statusCode == 401) {
        await handleSessionExpired(context);
      } else if (e.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền')),
        );
      }
      rethrow;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureProducts = _fetch();
    });
    try {
      await _futureProducts;
    } catch (_) {
      // Loi da hien trong FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm'),
        actions: const [BiometricOffButton(), LogoutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshMessage('${snapshot.error}');
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const RefreshMessage('Chưa có sản phẩm');
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: ProductImage(p.imageUrl),
                  title: Text(p.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh mục: ${p.categoryName ?? 'Chưa phân loại'}'
                        '${p.description == null ? '' : '\n${p.description}'}',
                      ),
                      StockText(p.quantity),
                    ],
                  ),
                  trailing: Text(formatPrice(p.price)),
                  // UP9: bam vao san pham -> xem chi tiet
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
