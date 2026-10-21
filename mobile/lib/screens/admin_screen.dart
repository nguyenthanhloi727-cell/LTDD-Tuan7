import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../services/user_service.dart';
import '../widgets/biometric_off_button.dart';
import '../widgets/logout_button.dart';
import '../widgets/refresh_message.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_image.dart';
import '../widgets/stock_text.dart';
import 'category_screen.dart';
import 'product_detail_screen.dart';
import 'user_management_screen.dart';

// Trang danh cho tai khoan co role Admin:
// danh sach san pham (them / sua day du), nut quan ly danh muc.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _productService = ProductService();
  final _categoryService = CategoryService();
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetch();
  }

  // Goi API; 401 (het han / bi thu hoi) -> ve man Dang nhap.
  Future<List<Product>> _fetch() async {
    try {
      return await _productService.getProducts();
    } catch (e) {
      if (mounted && isSessionExpired(e)) await handleSessionExpired(context);
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

  // Nut demo: thu hoi token cua chinh minh roi tai lai -> API tra 401 -> ve man Dang nhap.
  Future<void> _expireMyToken() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Làm hết hạn token?'),
        content: const Text(
            'Token hiện tại sẽ bị thu hồi, app sẽ quay về màn Đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserService().revokeMe();
      _reload();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryScreen()),
    );
    _reload(); // danh muc co the da bi sua/xoa
  }

  // Form them (p == null) / sua san pham: Ten, Gia, So luong, Danh muc.
  Future<void> _openForm([Product? p]) async {
    final List<Category> categories;
    try {
      categories = await _categoryService.getCategories();
    } catch (e) {
      _handleError(e);
      return;
    }
    if (!mounted) return;

    final result = await showDialog<Product>(
      context: context,
      builder: (_) => ProductFormDialog(product: p, categories: categories),
    );
    if (result == null) return;

    try {
      if (p == null) {
        await _productService.createProduct(result);
        _showMessage('Đã thêm sản phẩm');
      } else {
        await _productService.updateProduct(result);
      }
      _reload();
    } catch (e) {
      _handleError(e);
    }
  }

  // Xoa san pham: hoi xac nhan truoc, xoa xong tai lai danh sach.
  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Xóa "${p.name}"? Không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _productService.deleteProduct(p.id);
      _showMessage('Đã xóa "${p.name}"');
      _reload();
    } catch (e) {
      _handleError(e);
      // 404: san pham da bi xoa noi khac -> tai lai cho danh sach dung
      if (e is ApiException && e.statusCode == 404 && mounted) _reload();
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // 401 -> ve man Dang nhap, loi khac -> SnackBar.
  void _handleError(Object e) {
    if (!mounted) return;
    if (isSessionExpired(e)) {
      handleSessionExpired(context);
    } else {
      _showMessage('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Admin'),
        actions: [
          IconButton(
            tooltip: 'Quản lý danh mục',
            icon: const Icon(Icons.category),
            onPressed: _openCategories,
          ),
          IconButton(
            tooltip: 'Quản lý tài khoản',
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Làm hết hạn token (demo)',
            icon: const Icon(Icons.timer_off),
            onPressed: _expireMyToken,
          ),
          const BiometricOffButton(),
          const LogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
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
              padding: const EdgeInsets.only(bottom: 80), // chua cho cho nut Them
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: ProductImage(p.imageUrl),
                  title: Text(p.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danh mục: ${p.categoryName ?? 'Chưa phân loại'}'),
                      Text('Giá: ${p.price.toStringAsFixed(0)} đ'),
                      StockText(p.quantity),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // UP9: xem chi tiet giong ben User
                      IconButton(
                        tooltip: 'Xem chi tiết',
                        icon: const Icon(Icons.visibility),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sửa',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(p),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteProduct(p),
                      ),
                    ],
                  ),
                  onTap: () => _openForm(p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
