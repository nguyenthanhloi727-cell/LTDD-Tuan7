import 'package:flutter_test/flutter_test.dart';

import 'package:nguyenthanhloi_2380601289/main.dart';

void main() {
  testWidgets('Chua dang nhap thi hien man Dang nhap', (tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
  });
}
