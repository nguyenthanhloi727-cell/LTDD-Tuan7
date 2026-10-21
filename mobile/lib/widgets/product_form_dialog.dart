import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_image.dart';

// Form them / sua san pham (Ten, Gia, So luong, Danh muc, Mo ta, Anh).
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
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  int? _categoryId;
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _quantityController =
        TextEditingController(text: p == null ? '' : '${p.quantity}');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
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
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Chuoi rong -> null (khong co mo ta / khong co anh)
  String? _textOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null;

  // UP10: chon anh trong thu vien -> upload len backend -> dien duong dan vao o "Link anh".
  // Thu nho anh (maxWidth 1200, chat luong 85) de upload nhanh va duoi 5 MB.
  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return; // bam huy

    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final url = await ProductService().uploadImage(picked.path);
      _imageUrlController.text = url;
    } catch (e) {
      _uploadError = '$e';
    }
    if (mounted) setState(() => _uploading = false);
  }

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
        description: _textOrNull(_descriptionController),
        imageUrl: _textOrNull(_imageUrlController),
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                minLines: 1,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link ảnh',
                  hintText: 'Bấm "Chọn ảnh" hoặc dán https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Xem truoc: cap nhat moi khi o "Link anh" thay doi
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _imageUrlController,
                    builder: (_, value, _) => ProductImage(value.text, size: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(_uploading ? 'Đang tải lên...' : 'Chọn ảnh'),
                    ),
                  ),
                ],
              ),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _uploadError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
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
          onPressed: _uploading ? null : _save, // dang upload thi chua cho luu
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
