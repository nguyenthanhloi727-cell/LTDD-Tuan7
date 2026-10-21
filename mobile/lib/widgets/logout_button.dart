import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

// Nut dang xuat dat tren AppBar, dung chung cho trang User va trang Admin.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await AuthService().logout();
    if (!context.mounted) return;
    // Xoa het stack -> bam Back khong quay lai trang cu duoc
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Đăng xuất',
      onPressed: () => _confirmLogout(context),
    );
  }
}
