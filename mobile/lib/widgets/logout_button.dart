import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

// Hoi xac nhan -> xoa token -> ve LoginScreen.
// Dung chung cho LogoutButton (trang Admin) va tab Tai khoan (trang User).
Future<void> confirmLogout(BuildContext context) async {
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

// Nut dang xuat dat tren AppBar trang Admin.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Đăng xuất',
      onPressed: () => confirmLogout(context),
    );
  }
}
