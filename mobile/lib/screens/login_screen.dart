import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'admin_screen.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _biometricService = BiometricService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _biometricSupported = false; // may co van tay
  bool _biometricEnabled = false; // da bat dang nhap van tay

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final supported = await _biometricService.isSupported();
    final enabled = await _biometricService.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Goi API login. Tra ve null neu ok, nguoc lai la thong bao loi.
  // connectionError = true neu khong goi duoc API (khong phai do sai mat khau).
  Future<({String? error, bool connectionError})> _callLogin(
      String username, String password) async {
    setState(() => _loading = true);
    String? error;
    var connectionError = false;
    try {
      error = await _authService.login(username, password);
    } catch (e) {
      error = 'Không kết nối được API: $e';
      connectionError = true;
    }
    if (mounted) setState(() => _loading = false);
    return (error: error, connectionError: connectionError);
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showMessage('Nhập tên đăng nhập và mật khẩu');
      return;
    }

    final result = await _callLogin(username, password);
    if (!mounted) return;
    if (result.error != null) {
      _showMessage(result.error!);
      return;
    }
    // Dang nhap mat khau thanh cong tren may co van tay ma chua bat -> hoi bat
    if (_biometricSupported && !_biometricEnabled) {
      await _askEnableBiometric(username, password);
      if (!mounted) return;
    }
    await _goToHome();
  }

  Future<void> _askEnableBiometric(String username, String password) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng nhập bằng vân tay'),
        content: const Text('Bật đăng nhập bằng vân tay cho lần sau?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bật'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final saved = await _biometricService.saveCredentials(username, password);
    if (!mounted) return;
    _showMessage(saved
        ? 'Đã bật đăng nhập bằng vân tay'
        : 'Chưa bật được đăng nhập bằng vân tay');
  }

  // Doc username/password da luu (he dieu hanh hien hop thoai van tay) roi login
  Future<void> _loginWithBiometric() async {
    final credentials = await _biometricService.readCredentials();
    if (!mounted) return;
    if (credentials == null) {
      _showMessage('Đã hủy xác thực vân tay');
      return;
    }

    final result =
        await _callLogin(credentials['username']!, credentials['password']!);
    if (!mounted) return;
    if (result.connectionError) {
      _showMessage(result.error!);
      return;
    }
    if (result.error != null) {
      // API tu choi (vd da doi mat khau) -> xoa du lieu van tay cu
      await _biometricService.disable();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      _showMessage('Thông tin đã lưu không còn đúng. '
          'Hãy đăng nhập lại bằng mật khẩu.');
      return;
    }
    await _goToHome();
  }

  // Doc role trong token vua luu: Admin -> AdminScreen, con lai -> MainScreen
  Future<void> _goToHome() async {
    final token = await _authService.getToken();
    if (!mounted) return;
    final role = token == null ? 'User' : _authService.getRole(token);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            role == 'Admin' ? const AdminScreen() : const MainScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đăng nhập'),
              ),
            ),
            // Chi hien khi may ho tro va da bat van tay
            if (_biometricSupported && _biometricEnabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Đăng nhập bằng vân tay'),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
