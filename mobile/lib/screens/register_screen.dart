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
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _sendingOtp = false;
  bool _listeningSms = false;

  @override
  void dispose() {
    // Dang cho SMS ma thoat man hinh -> go listener cua smart_auth
    if (_listeningSms) SmartAuth.instance.removeUserConsentApiListener();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _initialsController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
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

  // UP5: nho backend gui ma OTP, roi cho SMS de tu dien ma.
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Nhập số điện thoại trước');
      return;
    }

    setState(() => _sendingOtp = true);
    String? error;
    try {
      error = await _authService.sendOtp(phone);
    } catch (e) {
      error = 'Không kết nối được API: $e';
    }
    if (!mounted) return;
    setState(() => _sendingOtp = false);

    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Đã gửi mã OTP, mã có hiệu lực 5 phút');
    if (Platform.isAndroid) _waitForOtpSms();
  }

  // smart_auth - SMS User Consent API: co SMS chua ma toi thi Android hoi
  // "Cho phep doc tin nhan?", bam Cho phep -> lay ma 6 so trong tin va dien vao o OTP.
  // Khong can quyen READ_SMS, khong can sua tin nhan theo dinh dang rieng.
  Future<void> _waitForOtpSms() async {
    if (_listeningSms) return; // dang cho roi (bam Gui ma lan 2)
    _listeningSms = true;
    final result =
        await SmartAuth.instance.getSmsWithUserConsentApi(matcher: r'\d{6}');
    _listeningSms = false;
    if (!mounted) return;

    final code = result.data?.code;
    if (result.hasData && code != null) {
      setState(() => _otpController.text = code);
      _showMessage('Đã tự điền mã OTP từ SMS');
    }
    // Bam Tu choi / het 5 phut khong co SMS -> nguoi dung tu go ma
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final initials = _initialsController.text.trim();
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nhập đủ tên đăng nhập, email, mật khẩu');
      return;
    }
    if (phone.isEmpty || otp.length != 6) {
      _showMessage('Nhập số điện thoại và mã OTP 6 số (bấm "Gửi mã")');
      return;
    }

    setState(() => _loading = true);
    String? error;
    try {
      error = await _authService.register(username, email, password, initials,
          phoneNumber: phone, otp: otp);
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
                labelText: 'Số điện thoại',
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
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Mã OTP',
                counterText: '',
                suffixIcon: TextButton(
                  onPressed: _sendingOtp ? null : _sendOtp,
                  child: const Text('Gửi mã'),
                ),
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
