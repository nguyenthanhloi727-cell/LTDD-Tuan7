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

// UP13: bo dau tieng Viet + chu thuong de tim kiem: "Chuột Không Dây" -> "chuot khong day".
const _vietnameseGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

String removeDiacritics(String text) {
  final buffer = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    var replaced = ch;
    for (final entry in _vietnameseGroups.entries) {
      if (entry.value.contains(ch)) {
        replaced = entry.key;
        break;
      }
    }
    buffer.write(replaced);
  }
  return buffer.toString();
}
