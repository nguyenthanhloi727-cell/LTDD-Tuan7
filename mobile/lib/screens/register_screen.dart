import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _initialsController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _initialsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // BT5: smart_auth - Phone Number Hint API (chi co tren Android, can Google Play services).
  // Hien hop thoai chon so dien thoai cua SIM, chon xong thi dien vao o SDT.
  Future<void> _pickPhoneNumber() async {
    final result = await SmartAuth.instance.requestPhoneNumberHint();
    if (!mounted) return;
    if (result.hasData) {
      setState(() => _phoneController.text = result.requireData);
    } else if (result.hasError) {
      _showMessage('Không lấy được số điện thoại từ SIM');
    }
    // Nguoi dung bam huy thi khong lam gi
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final initials = _initialsController.text.trim();
    final phone = _phoneController.text.trim();
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nhập đủ tên đăng nhập, email, mật khẩu');
      return;
    }

    setState(() => _loading = true);
    String? error;
    try {
      error = await _authService.register(username, email, password, initials,
          phoneNumber: phone.isEmpty ? null : phone);
    } catch (e) {
      error = 'Không kết nối được API: $e';
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Đăng ký thành công, hãy đăng nhập');
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                helperText: 'Ít nhất 6 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt',
              ),
            ),
            TextField(
              controller: _initialsController,
              decoration: const InputDecoration(labelText: 'Tên viết tắt'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại (không bắt buộc)',
                // Nut lay SDT tu SIM chi hien tren Android
                suffixIcon: Platform.isAndroid
                    ? IconButton(
                        icon: const Icon(Icons.sim_card),
                        tooltip: 'Lấy số từ SIM',
                        onPressed: _pickPhoneNumber,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đăng ký'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
