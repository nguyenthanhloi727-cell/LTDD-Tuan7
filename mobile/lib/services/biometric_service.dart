import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Luu username + password vao kho ma hoa cua biometric_storage.
// Doc/ghi kho nay thi he dieu hanh hien hop thoai van tay.
// Flag 'biometric_enabled' (shared_preferences) de biet da bat hay chua
// ma khong phai mo hop thoai van tay.
class BiometricService {
  static const String storageName = 'login_credentials';
  static const String enabledKey = 'biometric_enabled';

  static const _promptInfo = PromptInfo(
    androidPromptInfo: AndroidPromptInfo(
      title: 'Đăng nhập bằng vân tay',
      negativeButton: 'Hủy',
    ),
    iosPromptInfo: IosPromptInfo(
      saveTitle: 'Xác thực để lưu thông tin đăng nhập',
      accessTitle: 'Xác thực để đăng nhập',
    ),
  );

  // May co cam bien va da cai van tay thi moi ho tro
  Future<bool> isSupported() async {
    try {
      final response = await BiometricStorage().canAuthenticate();
      return response == CanAuthenticateResponse.success;
    } catch (e) {
      debugPrint('canAuthenticate loi: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  Future<BiometricStorageFile> _getStorage() {
    return BiometricStorage().getStorage(
      storageName,
      options: StorageFileInitOptions(authenticationRequired: true),
      promptInfo: _promptInfo,
    );
  }

  // Tra ve true neu luu thanh cong (nguoi dung bam Huy -> false)
  Future<bool> saveCredentials(String username, String password) async {
    try {
      final storage = await _getStorage();
      await storage
          .write(jsonEncode({'username': username, 'password': password}));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, true);
      return true;
    } catch (e) {
      debugPrint('Luu van tay loi: $e');
      return false;
    }
  }

  // Tra ve {'username', 'password'}; null neu nguoi dung huy, chua luu hoac loi
  Future<Map<String, String>?> readCredentials() async {
    try {
      final storage = await _getStorage();
      final content = await storage.read();
      if (content == null) return null;
      final data = jsonDecode(content);
      return {
        'username': data['username'] as String,
        'password': data['password'] as String,
      };
    } catch (e) {
      debugPrint('Doc van tay loi: $e');
      return null;
    }
  }

  // Tat dang nhap van tay: xoa du lieu da luu + flag
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(enabledKey);
    try {
      final storage = await _getStorage();
      await storage.delete();
    } catch (e) {
      debugPrint('Xoa van tay loi: $e');
    }
  }
}
