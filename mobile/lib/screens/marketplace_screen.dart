import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../widgets/product_image.dart';
import '../widgets/refresh_message.dart';
import '../widgets/stock_text.dart';
import '../utils/format.dart';
import 'product_detail_screen.dart';

// Tab Marketplace cua trang User: danh sach san pham (UP12 chuyen tu MainScreen sang).
// State de public (MarketplaceScreenState) de MainScreen goi applyFilter qua GlobalKey.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => MarketplaceScreenState();
}

class MarketplaceScreenState extends State<MarketplaceScreen> {
  final _productService = ProductService();
  late Future<List<Product>> _futureProducts;

  // Bo loc tab Trang chu gui sang (null = khong loc).
  String? _query;
  int? _categoryId;

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

  // Goi tu MainScreen.openMarketplace: loc theo ten / danh muc (goi khong tham so = bo loc).
  void applyFilter({String? query, int? categoryId}) {
    setState(() {
      _query = (query == null || query.trim().isEmpty) ? null : query.trim();
      _categoryId = categoryId;
    });
  }

  List<Product> _filter(List<Product> products) {
    return products.where((p) {
      final okName = _query == null ||
          p.name.toLowerCase().contains(_query!.toLowerCase());
      final okCategory = _categoryId == null || p.categoryId == _categoryId;
      return okName && okCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = _query != null || _categoryId != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          if (hasFilter)
            TextButton.icon(
              onPressed: () => applyFilter(),
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Bỏ lọc'),
            ),
        ],
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
            final products = _filter(snapshot.data ?? []);
            if (products.isEmpty) {
              return RefreshMessage(
                  hasFilter ? 'Không có sản phẩm phù hợp' : 'Chưa có sản phẩm');
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
