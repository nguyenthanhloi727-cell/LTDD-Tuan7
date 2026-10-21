import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/biometric_off_button.dart';
import '../widgets/logout_button.dart';

// Tab Tai khoan cua trang User: ten dang nhap + role (doc tu token),
// tat dang nhap van tay, dang xuat.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  String _username = '';
  String _role = '';
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _authService.getToken();
    final biometric = await BiometricService().isEnabled();
    if (!mounted) return;
    setState(() {
      if (token != null) {
        _username = _authService.getUsername(token);
        _role = _authService.getRole(token);
      }
      _biometricEnabled = biometric;
    });
  }

  Future<void> _disableBiometric() async {
    final disabled = await confirmDisableBiometric(context);
    if (disabled && mounted) setState(() => _biometricEnabled = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text(
                _username.isEmpty ? '?' : _username[0].toUpperCase(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(_username,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Center(child: Text('Vai trò: $_role')),
          const SizedBox(height: 24),
          const Divider(),
          if (_biometricEnabled)
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Tắt đăng nhập vân tay'),
              onTap: _disableBiometric,
            ),
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text('Đăng xuất', style: TextStyle(color: colors.error)),
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
