// Tai khoan trong danh sach Quan ly tai khoan (GET /api/Users).
class AppUser {
  final String id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String role;
  final bool isLocked;

  AppUser({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    required this.role,
    required this.isLocked,
  });

  bool get isAdmin => role == 'Admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String? ?? 'User',
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}
