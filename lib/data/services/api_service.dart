import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';

class Api {
  static final Api _i = Api._();
  factory Api() => _i;

  late final Dio _d;
  final _s = const FlutterSecureStorage();

  Api._() {
    _d = Dio(BaseOptions(baseUrl: K.baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15), headers: {'Content-Type': 'application/json'}));
    _d.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      // App Check token
      try {
        final appCheckToken = await FirebaseAppCheck.instance.getToken();
        if (appCheckToken != null) {
          o.headers['X-Firebase-AppCheck'] = appCheckToken;
        } else {
          print('[APP CHECK] getToken() returned null');
        }
      } catch (e) {
        print('[APP CHECK] getToken() error: $e');
      }
      // Firebase ID Token
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            o.headers['Authorization'] = 'Bearer $idToken';
          }
        }
      } catch (_) {}
      h.next(o);
    }, onError: (e, h) async {
      // Auto-refresh on 401 and retry once
      if (e.response?.statusCode == 401) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true); // force refresh
            if (newToken != null) {
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retry = await _d.fetch(e.requestOptions);
              return h.resolve(retry);
            }
          }
        } catch (_) {}
      }
      h.next(e);
    }));
  }

  // ── Firebase Auth helper ──
  Future<void> signInWithCustomToken(String customToken) async {
    await FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // ── Auth ──
  Future<Map<String, dynamic>> createAccount() async => (await _d.post('/auth/createAccount')).data;
  Future<Map<String, dynamic>> login(String acc) async => (await _d.post('/auth/login', data: {'accountNumber': acc})).data;
  Future<Map<String, dynamic>> nostrSignup(Map e) async => (await _d.post('/auth/nostr/signup', data: {'signedEvent': e})).data;
  Future<Map<String, dynamic>> nostrLogin(Map e) async => (await _d.post('/auth/nostr/login', data: {'signedEvent': e})).data;
  Future<Map<String, dynamic>> nostrLink(String acc, Map e) async => (await _d.post('/auth/nostr/link', data: {'accountNumber': acc, 'signedEvent': e})).data;

  // ── Device registration (FCM) ──
  Future<Map<String, dynamic>> registerDevice(String fcmToken) async => (await _d.post('/auth/register-device', data: {'fcmToken': fcmToken})).data;

  // ── Account deletion ──
  Future<Map<String, dynamic>> deleteAccount() async => (await _d.delete('/auth/delete-account')).data;

  // ── User ──
  Future<Map<String, dynamic>> stats(String acc) async => (await _d.get('/user/stats', queryParameters: {'accountNumber': acc})).data;
  Future<Map<String, dynamic>> history(String acc) async => (await _d.post('/history', data: {'accountNumber': acc})).data;

  // ── Remittance ──
  Future<Map<String, dynamic>> remitQuote({required int tzs, required String phone, required String name, required String acc}) async =>
      (await _d.post('/invoices/quote', data: {'metadata': {'amountTZS': tzs, 'phoneNumber': phone, 'recipientName': name, 'accountNumber': acc}})).data;
  Future<Map<String, dynamic>> remitPoll(String id) async => (await _d.get('/invoices/quote/$id')).data;
  Future<Map<String, dynamic>> remitGenerate(String qid) async => (await _d.post('/invoices/generate', data: {'quoteId': qid})).data;
  Future<Map<String, dynamic>> remitStatus(String iid) async => (await _d.get('/invoices/status/$iid')).data;

  // ── Airtime ──
  Future<Map<String, dynamic>> airQuote({required int tzs, required String phone, required String acc}) async =>
      (await _d.post('/airtime/quote', data: {'metadata': {'amountTZS': tzs, 'phoneNumber': phone, 'accountNumber': acc}})).data;
  Future<Map<String, dynamic>> airPoll(String id) async => (await _d.get('/airtime/quote/$id')).data;
  Future<Map<String, dynamic>> airGenerate(String qid) async => (await _d.post('/airtime/generate', data: {'quoteId': qid})).data;

  // ── Buy Sats ──
  Future<Map<String, dynamic>> buyQuote({required int tzs, required String acc, required String phone}) async =>
      (await _d.post('/buy/quote', data: {'amountTZS': tzs, 'accountNumber': acc, 'phoneNumber': phone})).data;
  Future<Map<String, dynamic>> buyPoll(String id) async => (await _d.get('/buy/quote/$id')).data;
  Future<Map<String, dynamic>> sendSats({required String qid, required String bolt11}) async =>
      (await _d.post('/buy/send-sats', data: {'quoteId': qid, 'bolt11': bolt11})).data;
  Future<Map<String, dynamic>> buyStatus(String orderId) async => (await _d.get('/buy/status/$orderId')).data;

  // ── Merchant ──
  Future<Map<String, dynamic>> merchantInfo(String mid) async => (await _d.get('/merchant/$mid')).data;
  Future<Map<String, dynamic>> merchantPay({required String mid, required int tzs}) async =>
      (await _d.post('/merchant/pay', data: {'merchantId': mid, 'amount': tzs})).data;
  Future<Map<String, dynamic>> merchantStatus(String iid) async => (await _d.get('/merchant/status/$iid')).data;
  Future<Map<String, dynamic>> merchantStats(String mid) async => (await _d.get('/merchant/$mid/stats')).data;
  Future<Map<String, dynamic>> merchantHistory(String mid) async => (await _d.get('/merchant/$mid/history')).data;

  // ── Name lookup ──
  Future<Map<String, dynamic>> nameLookup({required String type, required String mobile, required String acc}) async =>
      (await _d.post('/name-lookup', data: {'type': type, 'mobile': mobile, 'userAccount': acc})).data;

  // ── Health ──
  Future<bool> health() async {
    try { return (await Dio().get(K.baseUrl.replaceAll('/app/v1', '/'))).data['status'] == 'ok'; } catch (_) { return false; }
  }
}
