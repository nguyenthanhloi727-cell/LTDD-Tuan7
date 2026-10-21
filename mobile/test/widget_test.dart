import 'package:flutter_test/flutter_test.dart';

import 'package:nguyenthanhloi_2380601289/main.dart';

void main() {
  testWidgets('App hien tieu de danh sach san pham', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Danh sách sản phẩm'), findsOneWidget);
  });
}
