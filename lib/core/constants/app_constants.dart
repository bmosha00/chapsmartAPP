import 'package:flutter_dotenv/flutter_dotenv.dart';

class K {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://backend.chapsmart.com/app/v1';
  static const appVersion = '2.0.0';
  static const supportEmail = 'support@chapsmart.com';
  static const website = 'https://chapsmart.com';
  static const kAccount = 'account_number';
  static const kToken = 'firebase_token';
  static const kNostr = 'nostr_pubkey';
  static const kAuth = 'auth_method';
  static const remitMin = 2500;
  static const remitMax = 1000000;
  static const airMin = 500;
  static const airMax = 15000;
  static const buyMin = 1000;
  static const buyMax = 100000;
  static const merchMin = 2500;
  static const merchMax = 1000000;
  static const mpesaAgent = '1228685';
  static const quotePollSec = 60;
  static const statusPollSec = 5;
  static const tiers = {'BRONZE': 2.2, 'SILVER': 1.87, 'GOLD': 1.32};
}
