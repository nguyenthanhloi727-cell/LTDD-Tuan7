import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/product.dart';

// Form them / sua san pham (Ten, Gia, So luong, Danh muc).
// product == null -> them moi. Bam Luu -> pop ra Product moi, bam Huy -> pop null.
class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final List<Category> categories;

  const ProductFormDialog({super.key, this.product, required this.categories});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _quantityController =
        TextEditingController(text: p == null ? '' : '${p.quantity}');
    // Danh muc cu khong con trong danh sach -> coi nhu "Khong co"
    final id = p?.categoryId;
    _categoryId =
        widget.categories.any((c) => c.id == id) ? id : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.product;
    Navigator.pop(
      context,
      Product(
        id: old?.id ?? 0,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        description: old?.description,
        imageUrl: old?.imageUrl,
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // digitsOnly: chi cho go 0-9 -> khong go duoc dau "-" (khong co so am)
    final numberInput = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
                validator: _required,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá (đ)'),
                keyboardType: TextInputType.number,
                inputFormatters: numberInput,
                validator: _required,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                inputFormatters: numberInput,
                validator: _required,
              ),
              DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Không có'),
                  ),
                  ...widget.categories.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
