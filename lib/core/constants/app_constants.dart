import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://backend.chapsmart.com/api/v1';

  static String get adminUrl =>
      dotenv.env['API_BASE_URL']?.replaceAll('/api/v1', '/api/admin') ??
          'https://backend.chapsmart.com/api/admin';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['API_SECRET'] ?? '';

  // Secure storage keys
  static const String keyApiKey = 'api_key';
  static const String keyApiSecret = 'api_secret';
  static const String keyAccountNumber = 'account_number';
  static const String keyFirebaseToken = 'firebase_token';
  static const String keyNostrPubkey = 'nostr_pubkey';
  static const String keyAuthMethod = 'auth_method';

  // Fee tiers
  static const Map<String, double> tierFees = {
    'BRONZE': 2.2,
    'SILVER': 1.87,
    'GOLD': 1.32,
  };

  // Amount limits
  static const int remitMin = 1000;
  static const int remitMax = 1000000;
  static const int airtimeMin = 500;
  static const int airtimeMax = 15000;
  static const int buySatsMin = 1000;
  static const int buySatsMax = 20000;

  // M-Pesa agent number for buy sats
  static const String mpesaAgent = '1228685';

  // Quote poll interval
  static const int quotePollSeconds = 60;
}