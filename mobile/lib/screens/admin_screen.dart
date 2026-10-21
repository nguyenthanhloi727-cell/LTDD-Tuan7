import 'package:flutter/material.dart';

import '../widgets/logout_button.dart';

// Trang danh cho tai khoan co role Admin
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Admin'),
        actions: const [LogoutButton()],
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 64),
            SizedBox(height: 12),
            Text('Xin chào Admin', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
