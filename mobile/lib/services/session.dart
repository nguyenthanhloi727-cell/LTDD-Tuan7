import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import 'auth_service.dart';
import 'product_service.dart' show ApiException;

// Loi 401: token het han (exp) hoac bi Admin thu hoi / khoa tai khoan.
bool isSessionExpired(Object error) =>
    error is ApiException && error.statusCode == 401;

// Xoa token, bao SnackBar va ve man Dang nhap (xoa het cac man cu).
Future<void> handleSessionExpired(BuildContext context) async {
  await AuthService().logout();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Phiên đăng nhập hết hạn, hãy đăng nhập lại')),
  );
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
