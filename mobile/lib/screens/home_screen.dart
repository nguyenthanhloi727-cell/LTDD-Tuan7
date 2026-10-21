import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/refresh_message.dart';
import '../utils/format.dart';
import 'marketplace_screen.dart' show ProductSort;
import 'product_detail_screen.dart';

// Du lieu cua Trang chu: tai song song san pham + danh muc (Future.wait).
class _HomeData {
  final List<Product> products;
  final List<Category> categories;

  _HomeData(this.products, this.categories);
}

// Tab Trang chu cua trang User (UP14): loi chao, o tim kiem, banner,
// hang danh muc, "San pham moi", "Sap het hang".
// onOpenMarketplace: MainScreen truyen vao de chuyen sang tab Marketplace kem bo loc.
class HomeScreen extends StatefulWidget {
  final void Function({String? query, int? categoryId, ProductSort? sort})
      onOpenMarketplace;

  const HomeScreen({super.key, required this.onOpenMarketplace});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _newCount = 6; // so san pham trong muc "San pham moi"
  static const _lowStock = 5; // quantity <= 5 la "sap het hang"

  final _authService = AuthService();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();
  late Future<_HomeData> _futureData;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _futureData = _fetch();
    _loadUsername();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final token = await _authService.getToken();
    if (!mounted || token == null) return;
    setState(() => _username = _authService.getUsername(token));
  }

  // Goi 2 API cung luc; 401 -> dang xuat ve LoginScreen.
  Future<_HomeData> _fetch() async {
    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _categoryService.getCategories(),
      ]);
      return _HomeData(
        results[0] as List<Product>,
        results[1] as List<Category>,
      );
    } catch (e) {
      if (mounted && isSessionExpired(e)) {
        await handleSessionExpired(context);
      }
      rethrow;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureData = _fetch();
    });
    try {
      await _futureData;
    } catch (_) {
      // Loi da hien trong FutureBuilder.
    }
  }

  void _openDetail(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
    );
  }

  // Go roi Enter -> sang Marketplace tim theo chuoi do.
  void _search(String text) {
    widget.onOpenMarketplace(query: text);
    _searchController.clear();
  }

  // Icon theo ten danh muc (bo dau de so sanh)
  IconData _categoryIcon(String name) {
    final n = removeDiacritics(name);
    if (n.contains('dien thoai')) return Icons.smartphone;
    if (n.contains('laptop')) return Icons.laptop;
    if (n.contains('phu kien')) return Icons.headphones;
    return Icons.category;
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, $_username',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Hôm nay bạn muốn mua gì?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: const InputDecoration(
              hintText: 'Tìm sản phẩm...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ],
      ),
    );
  }

  // Banner gradient mau primary -> Marketplace sap xep Moi nhat
  Widget _buildBanner(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onOpenMarketplace(sort: ProductSort.newest),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hàng mới về',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Xem ngay →',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onPrimary)),
                    ],
                  ),
                ),
                Icon(Icons.local_mall, size: 56, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tieu de muc + nut "Xem tat ca" (tuy chon)
  Widget _buildSectionTitle(ThemeData theme, String title,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }

  // Hang ngang cac o tron danh muc; bam -> Marketplace loc danh muc do
  Widget _buildCategories(ThemeData theme, List<Category> categories) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = categories[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onOpenMarketplace(categoryId: c.id),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(_categoryIcon(c.name),
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 6),
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Danh sach ngang san pham moi (id lon nhat), dung lai ProductCard cua UP13
  Widget _buildNewProducts(List<Product> products) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = products[index];
          return SizedBox(
            width: 160,
            child: ProductCard(product: p, onTap: () => _openDetail(p)),
          );
        },
      ),
    );
  }

  Widget _buildLowStockTile(ThemeData theme, Product p) {
    return ListTile(
      leading: ProductImage(p.imageUrl, size: 48),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatPrice(p.price)),
      trailing: Text('Chỉ còn ${p.quantity}',
          style: TextStyle(
              color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
      onTap: () => _openDetail(p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<_HomeData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshMessage('${snapshot.error}');
            }
            final data = snapshot.data!;
            final newest = [...data.products]
              ..sort((a, b) => b.id.compareTo(a.id));
            final lowStock = data.products
                .where((p) => p.quantity > 0 && p.quantity <= _lowStock)
                .toList()
              ..sort((a, b) => a.quantity.compareTo(b.quantity));

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _buildHeader(theme),
                _buildBanner(theme),
                if (data.categories.isNotEmpty) ...[
                  _buildSectionTitle(theme, 'Danh mục'),
                  _buildCategories(theme, data.categories),
                ],
                _buildSectionTitle(theme, 'Sản phẩm mới',
                    onSeeAll: () => widget.onOpenMarketplace()),
                if (newest.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Chưa có sản phẩm'),
                  )
                else
                  _buildNewProducts(newest.take(_newCount).toList()),
                // Khong co san pham sap het hang -> an ca muc
                if (lowStock.isNotEmpty) ...[
                  _buildSectionTitle(theme, 'Sắp hết hàng'),
                  for (final p in lowStock) _buildLowStockTile(theme, p),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
