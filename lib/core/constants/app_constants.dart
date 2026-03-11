import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://your-api-domain.com/api/v1';

  static String get adminUrl =>
      dotenv.env['API_BASE_URL']?.replaceAll('/api/v1', '/api/admin') ?? 'https://your-api-domain.com/api/admin';

  static String get apiKey =>
      dotenv.env['API_KEY'] ?? '';

  static String get apiSecret =>
      dotenv.env['API_SECRET'] ?? '';

  // Secure storage keys
  static const String keyApiKey        = 'api_key';
  static const String keyApiSecret     = 'api_secret';
  static const String keyAccountNumber = 'account_number';
  static const String keyFirebaseToken = 'firebase_token';

  // Fee tiers
  static const Map<String, double> tierFees = {
    'BRONZE': 2.2,
    'SILVER': 1.87,
    'GOLD':   1.32,
  };

  // Quote poll interval
  static const int quotePollSeconds = 60;
}