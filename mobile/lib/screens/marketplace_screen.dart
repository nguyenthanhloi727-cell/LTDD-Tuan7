import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../widgets/product_card.dart';
import '../widgets/refresh_message.dart';
import '../utils/format.dart';
import 'product_detail_screen.dart';

// Cac kieu sap xep (UP13)
enum ProductSort { newest, priceAsc, priceDesc, nameAsc }

const _sortLabels = {
  ProductSort.newest: 'Mới nhất',
  ProductSort.priceAsc: 'Giá tăng dần',
  ProductSort.priceDesc: 'Giá giảm dần',
  ProductSort.nameAsc: 'Tên A→Z',
};

// Tab Marketplace cua trang User (UP12 chuyen tu MainScreen sang, UP13 doi sang luoi).
// Tai san pham + danh muc 1 lan; tim / loc / sap xep lam o app tren danh sach da tai.
// State de public (MarketplaceScreenState) de MainScreen goi applyFilter qua GlobalKey.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => MarketplaceScreenState();
}

class MarketplaceScreenState extends State<MarketplaceScreen> {
  // categoryId dac biet cho chip "Chua phan loai" (id that trong DB luon > 0)
  static const uncategorizedId = -1;

  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();
  late Future<List<Product>> _futureProducts;
  List<Category> _categories = [];

  // Bo loc hien tai (null = khong loc)
  String? _query;
  int? _categoryId;
  ProductSort _sort = ProductSort.newest;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Goi API san pham + danh muc; 401 -> dang xuat ve LoginScreen, 403 -> bao "Khong co quyen".
  Future<List<Product>> _fetch() async {
    try {
      final products = await _productService.getProducts();
      _categories = await _categoryService.getCategories();
      return products;
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

  // Goi tu MainScreen.openMarketplace (tab Trang chu, UP14): loc theo ten / danh muc.
  // Goi khong tham so = bo loc.
  void applyFilter({String? query, int? categoryId}) {
    final q = query?.trim() ?? '';
    _searchController.text = q;
    setState(() {
      _query = q.isEmpty ? null : q;
      _categoryId = categoryId;
    });
  }

  void _onSearchChanged(String text) {
    setState(() {
      _query = text.trim().isEmpty ? null : text.trim();
    });
  }

  // Tim theo ten (khong phan biet hoa thuong, bo dau) + loc danh muc + sap xep.
  List<Product> _filter(List<Product> products) {
    final key = _query == null ? null : removeDiacritics(_query!);
    final result = products.where((p) {
      final okName = key == null || removeDiacritics(p.name).contains(key);
      final okCategory = _categoryId == null ||
          (_categoryId == uncategorizedId
              ? p.categoryId == null
              : p.categoryId == _categoryId);
      return okName && okCategory;
    }).toList();

    switch (_sort) {
      case ProductSort.newest:
        result.sort((a, b) => b.id.compareTo(a.id));
      case ProductSort.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.nameAsc:
        result.sort((a, b) =>
            removeDiacritics(a.name).compareTo(removeDiacritics(b.name)));
    }
    return result;
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm sản phẩm...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query == null
              ? null
              : IconButton(
                  tooltip: 'Xóa',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
        ),
      ),
    );
  }

  // Hang chip cuon ngang: Tat ca + tung danh muc + Chua phan loai
  Widget _buildCategoryChips() {
    Widget chip(String label, int? id) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _categoryId == id,
            onSelected: (_) => setState(() => _categoryId = id),
          ),
        );

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          chip('Tất cả', null),
          for (final c in _categories) chip(c.name, c.id),
          chip('Chưa phân loại', uncategorizedId),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          PopupMenuButton<ProductSort>(
            tooltip: 'Sắp xếp',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => [
              for (final entry in _sortLabels.entries)
                CheckedPopupMenuItem(
                  value: entry.key,
                  checked: _sort == entry.key,
                  child: Text(entry.value),
                ),
            ],
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
            final all = snapshot.data ?? [];
            if (all.isEmpty) {
              return const RefreshMessage('Chưa có sản phẩm');
            }
            final products = _filter(all);

            // Ca man la 1 CustomScrollView -> keo xuong o dau cung tai lai duoc
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBox()),
                SliverToBoxAdapter(child: _buildCategoryChips()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('${products.length} sản phẩm · '
                        '${_sortLabels[_sort]}'),
                  ),
                ),
                if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Không tìm thấy sản phẩm'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => applyFilter(),
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text('Xóa bộ lọc'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return ProductCard(
                          product: p,
                          // UP9: bam vao san pham -> xem chi tiet
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: p)),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
