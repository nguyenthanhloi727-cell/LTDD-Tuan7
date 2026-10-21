import 'package:flutter_test/flutter_test.dart';

import 'package:nguyenthanhloi_2380601289/main.dart';
import 'package:nguyenthanhloi_2380601289/screens/login_screen.dart';

void main() {
  testWidgets('Chua dang nhap thi mo LoginScreen', (tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
