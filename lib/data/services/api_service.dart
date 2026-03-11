import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        var apiKey = await _storage.read(key: AppConstants.keyApiKey);
        var apiSecret = await _storage.read(key: AppConstants.keyApiSecret);

        if (apiKey == null || apiKey.isEmpty) {
          apiKey = AppConstants.apiKey;
          if (apiKey.isNotEmpty) {
            await _storage.write(key: AppConstants.keyApiKey, value: apiKey);
          }
        }
        if (apiSecret == null || apiSecret.isEmpty) {
          apiSecret = AppConstants.apiSecret;
          if (apiSecret.isNotEmpty) {
            await _storage.write(
                key: AppConstants.keyApiSecret, value: apiSecret);
          }
        }

        if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
          options.headers['X-API-Key'] = apiKey;
          options.headers['X-API-Secret'] = apiSecret;
        }
        AppLogger.info('→ ${options.method} ${options.path}');
        handler.next(options);
      },
      onError: (error, handler) {
        AppLogger.error(
            'API Error: ${error.response?.statusCode} ${error.message}');
        handler.next(error);
      },
    ));
  }

  // ─── Auth ───────────────────────────────────────────────

  Future<Map<String, dynamic>> createAccount() async {
    final res = await _dio.post('/auth/createAccount');
    return res.data;
  }

  Future<Map<String, dynamic>> login(String accountNumber) async {
    final res =
    await _dio.post('/auth/login', data: {'accountNumber': accountNumber});
    return res.data;
  }

  Future<bool> verifySession(String token, String accountNumber) async {
    try {
      final res = await _dio.post('/auth/verify-session', data: {
        'token': token,
        'accountNumber': accountNumber,
      });
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Nostr Auth ──────────────────────────────────────────

  Future<Map<String, dynamic>> nostrSignup(
      Map<String, dynamic> signedEvent) async {
    final res = await _dio
        .post('/auth/nostr/signup', data: {'signedEvent': signedEvent});
    return res.data;
  }

  Future<Map<String, dynamic>> nostrLogin(
      Map<String, dynamic> signedEvent) async {
    final res = await _dio
        .post('/auth/nostr/login', data: {'signedEvent': signedEvent});
    return res.data;
  }

  Future<Map<String, dynamic>> nostrLink(
      String accountNumber, Map<String, dynamic> signedEvent) async {
    final res = await _dio.post('/auth/nostr/link', data: {
      'accountNumber': accountNumber,
      'signedEvent': signedEvent,
    });
    return res.data;
  }

  // ─── User ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserStats(String accountNumber) async {
    final res = await _dio
        .get('/user/stats', queryParameters: {'accountNumber': accountNumber});
    return res.data;
  }

  // ─── History ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getHistory(String accountNumber) async {
    final res =
    await _dio.post('/history', data: {'accountNumber': accountNumber});
    return res.data;
  }

  // ─── Remittance Invoices ─────────────────────────────────

  Future<Map<String, dynamic>> createQuote({
    required int amountTZS,
    required String phoneNumber,
    required String recipientName,
    required String accountNumber,
  }) async {
    final res = await _dio.post('/invoices/quote', data: {
      'metadata': {
        'amountTZS': amountTZS,
        'phoneNumber': phoneNumber,
        'recipientName': recipientName,
        'accountNumber': accountNumber,
      },
    });
    return res.data;
  }

  Future<Map<String, dynamic>> pollQuote(String quoteId) async {
    final res = await _dio.get('/invoices/quote/$quoteId');
    return res.data;
  }

  Future<Map<String, dynamic>> generateInvoice(String quoteId) async {
    final res =
    await _dio.post('/invoices/generate', data: {'quoteId': quoteId});
    return res.data;
  }

  // ─── Airtime ─────────────────────────────────────────────

  Future<Map<String, dynamic>> createAirtimeQuote({
    required int amountTZS,
    required String phoneNumber,
    required String accountNumber,
  }) async {
    final res = await _dio.post('/airtime/quote', data: {
      'metadata': {
        'amountTZS': amountTZS,
        'phoneNumber': phoneNumber,
        'accountNumber': accountNumber,
      },
    });
    return res.data;
  }

  Future<Map<String, dynamic>> pollAirtimeQuote(String quoteId) async {
    final res = await _dio.get('/airtime/quote/$quoteId');
    return res.data;
  }

  Future<Map<String, dynamic>> generateAirtimeInvoice(String quoteId) async {
    final res =
    await _dio.post('/airtime/generate', data: {'quoteId': quoteId});
    return res.data;
  }

  // ─── Buy Sats ────────────────────────────────────────────

  Future<Map<String, dynamic>> createBuyQuote({
    required int amountTZS,
    required String accountNumber,
  }) async {
    final res = await _dio.post('/buy/quote', data: {
      'amountTZS': amountTZS,
      'accountNumber': accountNumber,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getBuyQuote(String quoteId) async {
    final res = await _dio.get('/buy/quote/$quoteId');
    return res.data;
  }

  Future<Map<String, dynamic>> mpesaLookup(String mpesaId) async {
    final res =
    await _dio.post('/buy/mpesa-lookup', data: {'mpesaId': mpesaId});
    return res.data;
  }

  Future<Map<String, dynamic>> sendSats({
    required String quoteId,
    required String bolt11,
    required String mpesaId,
  }) async {
    final res = await _dio.post('/buy/send-sats', data: {
      'quoteId': quoteId,
      'bolt11': bolt11,
      'mpesaId': mpesaId,
    });
    return res.data;
  }

  // ─── Name Lookup ─────────────────────────────────────────

  Future<Map<String, dynamic>> nameLookup({
    required String type,
    required String mobile,
    required String userAccount,
  }) async {
    final res = await _dio.post('/name-lookup', data: {
      'type': type,
      'mobile': mobile,
      'userAccount': userAccount,
    });
    return res.data;
  }

  // ─── Health ──────────────────────────────────────────────

  Future<bool> healthCheck() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl.replaceAll('/api/v1', ''),
      ));
      final res = await dio.get('/');
      return res.data['status'] == 'online';
    } catch (_) {
      return false;
    }
  }
}