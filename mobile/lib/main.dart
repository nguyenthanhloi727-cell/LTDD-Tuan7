import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/admin_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Tu dang nhap: con token va chua het han thi vao dung trang theo role
  final authService = AuthService();
  String? role;
  if (await authService.getToken() != null) {
    final validToken = await authService.getValidToken();
    if (validToken != null) {
      role = authService.getRole(validToken);
    } else {
      // Token het han -> xoa token, ve LoginScreen
      await authService.logout();
    }
  }

  runApp(MyApp(role: role));
}

class MyApp extends StatelessWidget {
  // null = chua dang nhap, con lai la "Admin" hoac "User"
  final String? role;

  const MyApp({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (role == 'Admin') {
      home = const AdminScreen();
    } else if (role == 'User') {
      home = const MainScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'LTDD Tuần 7',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: home,
    );
  }
}
