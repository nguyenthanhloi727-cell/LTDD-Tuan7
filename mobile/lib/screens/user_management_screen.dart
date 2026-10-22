import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/session.dart';
import '../services/user_service.dart';
import '../widgets/refresh_message.dart';

// Trang Admin: xem danh sach tai khoan, khoa / mo khoa, doi role (UP15).
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
    _futureUsers = _fetch();
  }

  // Goi API; 401 (het han / bi thu hoi) -> ve man Dang nhap.
  Future<List<AppUser>> _fetch() async {
    try {
      return await _service.getUsers();
    } catch (e) {
      if (mounted && isSessionExpired(e)) await handleSessionExpired(context);
      rethrow;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureUsers = _fetch();
    });
    try {
      await _futureUsers;
    } catch (_) {
      // Loi da hien trong FutureBuilder.
    }
  }

  // 401 -> ve man Dang nhap, con lai -> SnackBar.
  void _showMessage(Object message) {
    if (!mounted) return;
    if (isSessionExpired(message)) {
      handleSessionExpired(context);
      return;
    }
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

  // "Buoc dang xuat": thu hoi moi token cua user, user phai dang nhap lai.
  Future<void> _revoke(AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buộc đăng xuất "${u.username}"?'),
        content: const Text(
            'Token hiện tại của tài khoản này hết dùng được, phải đăng nhập lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buộc đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.revoke(u.id);
      _showMessage('Đã buộc đăng xuất "${u.username}"');
    } catch (e) {
      _showMessage(e);
    }
  }

  // UP15: chon role moi trong dialog -> goi API. Khong co lua chon Admin (chi 1 Admin).
  static const _roleNames = {
    'Manager': 'Manager (quản lý hàng)',
    'Employee': 'Employee (nhân viên, chỉ xem)',
    'User': 'User (khách hàng)',
  };

  Future<void> _changeRole(AppUser u) async {
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Đổi role "${u.username}"'),
        children: [
          for (final entry in _roleNames.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, entry.key),
              child: Row(
                children: [
                  Icon(entry.key == u.role
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            ),
        ],
      ),
    );
    if (role == null || role == u.role) return;
    try {
      await _service.changeRole(u.id, role);
      _showMessage('Đã đổi "${u.username}" thành $role (phải đăng nhập lại)');
      _reload();
    } catch (e) {
      _showMessage(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AppUser>>(
          future: _futureUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshMessage('${snapshot.error}');
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const RefreshMessage('Chưa có tài khoản');
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  // Dong Admin khong co nut doi role / khoa / buoc dang xuat
                  trailing: u.isAdmin
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Đổi role',
                              icon: const Icon(Icons.manage_accounts),
                              onPressed: () => _changeRole(u),
                            ),
                            IconButton(
                              tooltip: 'Buộc đăng xuất',
                              icon: const Icon(Icons.logout),
                              onPressed: () => _revoke(u),
                            ),
                            IconButton(
                              tooltip: u.isLocked ? 'Mở khóa' : 'Khóa',
                              icon: Icon(
                                  u.isLocked ? Icons.lock_open : Icons.lock),
                              onPressed: () => _toggleLock(u),
                            ),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
