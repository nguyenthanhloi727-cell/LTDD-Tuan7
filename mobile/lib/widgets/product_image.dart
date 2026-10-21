import 'package:flutter/material.dart';

import '../config/config_url.dart';

// Anh san pham (UP8). imageUrl co 2 dang:
// - Link day du "https://..." -> dung luon
// - Duong dan tren backend "/uploads/products/abc.jpg" (anh upload, UP10) -> ghep BASE_URL
// Khong co anh / tai loi -> icon tui nhu cu.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProductImage(this.imageUrl, {super.key, this.size = 56});

  static String? fullUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final u = url.trim();
    return u.startsWith('/') ? '${ConfigUrl.baseUrl}$u' : u;
  }

  @override
  Widget build(BuildContext context) {
    final url = fullUrl(imageUrl);
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(Icons.shopping_bag, size: size * 0.5, color: Colors.grey),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}
