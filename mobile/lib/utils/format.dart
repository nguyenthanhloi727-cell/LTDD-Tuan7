// UP11: 20990000 -> "20.990.000 đ" (tu chen dau cham moi 3 so, khong dung intl)
String formatPrice(num price) {
  final digits = price.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // Con lai boi so cua 3 chu so phia sau -> chen dau cham
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final sign = price < 0 ? '-' : '';
  //  : khoang trang khong ngat dong, "đ" khong bi tach xuong dong rieng
  return '$sign$buffer đ';
}
