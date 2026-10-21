import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/session.dart';
import '../services/user_service.dart';
import '../widgets/biometric_off_button.dart';
import '../widgets/logout_button.dart';
import 'category_screen.dart';
import 'user_management_screen.dart';

// Trang danh cho tai khoan co role Admin:
// danh sach san pham, bam vao san pham de chon danh muc; nut quan ly danh muc.
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

  void _reload() {
    setState(() {
      _futureProducts = _fetch();
    });
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

  // Dialog Dropdown chon danh muc cho san pham (null = "Khong co").
  Future<void> _chooseCategory(Product p) async {
    final List<Category> categories;
    try {
      categories = await _categoryService.getCategories();
    } catch (e) {
      _handleError(e);
      return;
    }
    if (!mounted) return;

    int? selected = p.categoryId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Danh mục của "${p.name}"'),
          content: DropdownButton<int?>(
            isExpanded: true,
            value: selected,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Không có'),
              ),
              ...categories.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  )),
            ],
            onChanged: (v) => setDialogState(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    try {
      await _productService.updateProduct(Product(
        id: p.id,
        name: p.name,
        price: p.price,
        description: p.description,
        imageUrl: p.imageUrl,
        categoryId: selected,
      ));
      _reload();
    } catch (e) {
      _handleError(e);
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
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(p.name),
                subtitle:
                    Text('Danh mục: ${p.categoryName ?? 'Chưa phân loại'}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _chooseCategory(p),
              );
            },
          );
        },
      ),
    );
  }
}
