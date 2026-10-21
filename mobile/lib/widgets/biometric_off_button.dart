import 'package:flutter/material.dart';

import '../services/biometric_service.dart';

// Nut "Tat dang nhap van tay" tren AppBar, dung chung cho trang User va Admin.
// Chi hien khi da bat van tay.
class BiometricOffButton extends StatefulWidget {
  const BiometricOffButton({super.key});

  @override
  State<BiometricOffButton> createState() => _BiometricOffButtonState();
}

class _BiometricOffButtonState extends State<BiometricOffButton> {
  final _biometricService = BiometricService();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _biometricService.isEnabled().then((enabled) {
      if (mounted) setState(() => _enabled = enabled);
    });
  }

  Future<void> _confirmDisable() async {
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
    if (ok != true) return;
    await _biometricService.disable();
    if (!mounted) return;
    setState(() => _enabled = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tắt đăng nhập bằng vân tay')),
    );
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
