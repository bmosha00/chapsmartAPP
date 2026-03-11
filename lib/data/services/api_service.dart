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
        // Try secure storage first
        var apiKey    = await _storage.read(key: AppConstants.keyApiKey);
        var apiSecret = await _storage.read(key: AppConstants.keyApiSecret);

        // Fall back to .env and save to secure storage for next time
        if (apiKey == null || apiKey.isEmpty) {
          apiKey = AppConstants.apiKey;
          if (apiKey.isNotEmpty) {
            await _storage.write(key: AppConstants.keyApiKey, value: apiKey);
          }
        }
        if (apiSecret == null || apiSecret.isEmpty) {
          apiSecret = AppConstants.apiSecret;
          if (apiSecret.isNotEmpty) {
            await _storage.write(key: AppConstants.keyApiSecret, value: apiSecret);
          }
        }

        if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
          options.headers['X-API-Key']    = apiKey;
          options.headers['X-API-Secret'] = apiSecret;
        }
        AppLogger.info('→ ${options.method} ${options.path}');
        handler.next(options);
      },
      onError: (error, handler) {
        AppLogger.error('API Error: ${error.response?.statusCode} ${error.message}');
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
    final res = await _dio.post('/auth/login', data: {'accountNumber': accountNumber});
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

  // ─── User ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserStats(String accountNumber) async {
    final res = await _dio.get('/user/stats', queryParameters: {'accountNumber': accountNumber});
    return res.data;
  }

  // ─── History ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getHistory(String accountNumber) async {
    final res = await _dio.post('/history', data: {'accountNumber': accountNumber});
    return res.data;
  }

  // ─── Invoices ────────────────────────────────────────────

  Future<Map<String, dynamic>> createQuote({
    required int amountTZS,
    required String phoneNumber,
    required String recipientName,
    required String description,
    required String accountNumber,
  }) async {
    final res = await _dio.post('/invoices/quote', data: {
      'metadata': {
        'amountTZS':     amountTZS,
        'phoneNumber':   phoneNumber,
        'recipientName': recipientName,
        'description':   description,
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
    final res = await _dio.post('/invoices/generate', data: {'quoteId': quoteId});
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