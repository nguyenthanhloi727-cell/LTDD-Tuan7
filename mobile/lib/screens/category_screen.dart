import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_service.dart';

// Trang Admin: quan ly danh muc (them, sua, xoa).
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = CategoryService();
  late Future<List<Category>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _futureCategories = _service.getCategories();
  }

  void _reload() {
    setState(() {
      _futureCategories = _service.getCategories();
    });
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }

  // Dialog nhap ten; tra ve ten moi hoac null neu bam Huy.
  Future<String?> _askName(String title, [String initial = '']) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên danh mục'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final name = await _askName('Thêm danh mục');
    if (name == null || name.isEmpty) return;
    try {
      await _service.createCategory(name);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _edit(Category c) async {
    final name = await _askName('Sửa danh mục', c.name);
    if (name == null || name.isEmpty) return;
    try {
      await _service.updateCategory(
        Category(id: c.id, name: name, description: c.description),
      );
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa "${c.name}"?'),
        content: const Text(
            'Sản phẩm trong danh mục này sẽ thành Chưa phân loại.'),
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
      await _service.deleteCategory(c.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý danh mục')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Category>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _edit(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _delete(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
