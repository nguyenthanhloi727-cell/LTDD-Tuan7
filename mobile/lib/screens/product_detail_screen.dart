import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/product_image.dart';
import '../widgets/stock_text.dart';
import '../utils/format.dart';

// UP9: xem chi tiet 1 san pham. User mo tu MainScreen (bam vao san pham),
// Admin mo tu AdminScreen (nut "Xem chi tiet"). Chi xem, khong sua.
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final textTheme = Theme.of(context).textTheme;
    final description = p.description?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Anh vuong, rong het man hinh
          LayoutBuilder(
            builder: (context, constraints) =>
                ProductImage(p.imageUrl, size: constraints.maxWidth),
          ),
          const SizedBox(height: 16),
          Text(p.name, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            formatPrice(p.price),
            style: textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StockText(p.quantity),
          const Divider(height: 32),
          _InfoRow(
            icon: Icons.category,
            label: 'Danh mục',
            value: p.categoryName ?? 'Chưa phân loại',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.notes,
            label: 'Mô tả',
            value: description.isEmpty ? 'Chưa có mô tả' : description,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
