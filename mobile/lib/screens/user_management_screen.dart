import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

// Trang Admin: xem danh sach tai khoan, khoa / mo khoa tai khoan User.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _service = UserService();
  late Future<List<AppUser>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = _service.getUsers();
  }

  void _reload() {
    setState(() {
      _futureUsers = _service.getUsers();
    });
  }

  void _showMessage(Object message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message')),
    );
  }

  // Dialog xac nhan roi goi lock / unlock.
  Future<void> _toggleLock(AppUser u) async {
    final action = u.isLocked ? 'Mở khóa' : 'Khóa';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action tài khoản "${u.username}"?'),
        content: Text(u.isLocked
            ? 'Tài khoản sẽ đăng nhập lại được.'
            : 'Tài khoản sẽ không đăng nhập được nữa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (u.isLocked) {
        await _service.unlock(u.id);
      } else {
        await _service.lock(u.id);
      }
      _showMessage('Đã ${action.toLowerCase()} "${u.username}"');
      _reload();
    } catch (e) {
      _showMessage(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: FutureBuilder<List<AppUser>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Chưa có tài khoản'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                leading: Icon(
                  u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: u.isLocked ? Colors.red : null,
                ),
                title: Text(u.username),
                subtitle: Text(
                  '${u.email ?? ''}\n'
                  'Role: ${u.role}${u.isLocked ? ' • Đang khóa' : ''}',
                ),
                isThreeLine: true,
                // Dong Admin khong co nut khoa
                trailing: u.isAdmin
                    ? null
                    : IconButton(
                        tooltip: u.isLocked ? 'Mở khóa' : 'Khóa',
                        icon: Icon(u.isLocked ? Icons.lock_open : Icons.lock),
                        onPressed: () => _toggleLock(u),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
