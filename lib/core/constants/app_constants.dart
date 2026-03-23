import 'package:flutter_dotenv/flutter_dotenv.dart';

class K {
  // API — now uses /app/v1 (App Check auth, no API key needed)
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://backend.chapsmart.com/app/v1';

  // Secure storage keys
  static const kAccount = 'account_number';
  static const kToken = 'firebase_token';
  static const kNostr = 'nostr_pubkey';
  static const kAuth = 'auth_method';

  // Product limits (API v7)
  static const remitMin = 2500;
  static const remitMax = 1000000;
  static const airMin = 500;
  static const airMax = 15000;
  static const buyMin = 1000;
  static const buyMax = 20000;
  static const merchMin = 2500;
  static const merchMax = 1000000;

  // M-Pesa agent for buy sats
  static const mpesaAgent = '1228685';

  // Poll intervals
  static const quotePollSec = 60;
  static const statusPollSec = 5;

  // Fee tiers
  static const tiers = {'BRONZE': 2.2, 'SILVER': 1.87, 'GOLD': 1.32};
}