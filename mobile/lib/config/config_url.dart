import 'package:flutter_dotenv/flutter_dotenv.dart';

// Dia chi API doc tu file .env (BASE_URL). Emulator Android goi may that qua 10.0.2.2.
class ConfigUrl {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5080';

  static String get login => '$baseUrl/api/Authenticate/login';
  static String get register => '$baseUrl/api/Authenticate/register';
  static String get products => '$baseUrl/api/Products';
}
