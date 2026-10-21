import 'package:flutter/material.dart';

import '../services/biometric_service.dart';

// Hoi xac nhan -> tat van tay -> SnackBar. Tra ve true neu da tat.
// Dung chung cho BiometricOffButton (trang Admin) va tab Tai khoan (trang User).
Future<bool> confirmDisableBiometric(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tắt đăng nhập vân tay'),
      content: const Text('Xóa thông tin đăng nhập đã lưu bằng vân tay?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Tắt'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await BiometricService().disable();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tắt đăng nhập bằng vân tay')),
    );
  }
  return true;
}

// Nut "Tat dang nhap van tay" tren AppBar trang Admin.
// Chi hien khi da bat van tay.
class BiometricOffButton extends StatefulWidget {
  const BiometricOffButton({super.key});

  @override
  State<BiometricOffButton> createState() => _BiometricOffButtonState();
}

class _BiometricOffButtonState extends State<BiometricOffButton> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    BiometricService().isEnabled().then((enabled) {
      if (mounted) setState(() => _enabled = enabled);
    });
  }

  Future<void> _confirmDisable() async {
    final disabled = await confirmDisableBiometric(context);
    if (disabled && mounted) setState(() => _enabled = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.fingerprint),
      tooltip: 'Tắt đăng nhập vân tay',
      onPressed: _confirmDisable,
    );
  }
}
