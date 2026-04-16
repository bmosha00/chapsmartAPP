import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

enum _Step { form, quoteAndBolt11, processing }

class BuySatsScreen extends StatefulWidget {
  const BuySatsScreen({super.key});
  @override
  State<BuySatsScreen> createState() => _S();
}

class _S extends State<BuySatsScreen> {
  final _fk = GlobalKey<FormState>();
  final _amt = TextEditingController();
  final _phone = TextEditingController();
  final _bolt = TextEditingController();
  final _s = const FlutterSecureStorage();
  final _api = Api();
  _Step _step = _Step.form;
  bool _busy = false;
  Map<String, dynamic>? _q;
  Timer? _poll;
  String? _boundPhone;
  bool _phoneLocked = false;

  // Phase for StepTracker: 0 = waiting USSD, 1 = payment received, 2 = sats sent
  int _phase = 0;
  bool _failed = false;
  String _failMsg = '';
  int? _satsSent;

  @override
  void initState() { super.initState(); _loadBoundPhone(); }

  @override
  void dispose() { _poll?.cancel(); _amt.dispose(); _phone.dispose(); _bolt.dispose(); super.dispose(); }

  /// Extract actual error message from DioException response body
  String _extractError(dynamic e, [String fallback = 'Something went wrong']) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      return (data['error'] ?? data['message'] ?? fallback).toString();
    }
    return fallback;
  }

  /// Get HTTP status code from DioException
  int? _statusCode(dynamic e) => e is DioException ? e.response?.statusCode : null;

  /// Pre-fill bound phone if account already has one
  Future<void> _loadBoundPhone() async {
    final saved = await _s.read(key: 'bound_phone');
    if (saved != null && saved.isNotEmpty && mounted) {
      final display = saved.startsWith('255') ? '0${saved.substring(3)}' : saved;
      setState(() {
        _boundPhone = saved;
        _phone.text = display;
        _phoneLocked = true;
      });
    }
  }

  /// Normalize phone to 255xxxxxxxxx format
  String _normalizePhone(String raw) {
    String p = raw.replaceAll(RegExp(r'\s+'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0')) p = '255${p.substring(1)}';
    if (!p.startsWith('255')) p = '255$p';
    return p;
  }

  Future<void> _getQuote() async {
    if (!_fk.currentState!.validate()) return;

    final phoneRaw = _phone.text.trim();
    if (!_phoneLocked && (phoneRaw.isEmpty || phoneRaw.length < 9)) {
      _err('Ingiza namba yako ya simu');
      return;
    }

    final phoneNumber = _normalizePhone(phoneRaw);

    setState(() => _busy = true);
    try {
      final a = await _s.read(key: K.kAccount) ?? '';

      final r = await _api.buyQuote(
        tzs: int.parse(_amt.text.replaceAll(',', '')),
        acc: a,
        phone: _boundPhone ?? phoneNumber,
      );

      // Cache bound phone from response
      final bp = r['boundPhone'] as String?;
      if (bp != null && bp.isNotEmpty) {
        await _s.write(key: 'bound_phone', value: bp);
        setState(() {
          _boundPhone = bp;
          _phoneLocked = true;
          _phone.text = bp.startsWith('255') ? '0${bp.substring(3)}' : bp;
        });
      } else if (!_phoneLocked) {
        await _s.write(key: 'bound_phone', value: phoneNumber);
        setState(() { _boundPhone = phoneNumber; _phoneLocked = true; });
      }

      setState(() { _q = r; _step = _Step.quoteAndBolt11; });
    } catch (e) {
      final code = _statusCode(e);
      final msg = _extractError(e, '');

      if (code == 403 && (msg.contains('linked to a different') ||
          msg.contains('already linked') || msg.contains('disabled'))) {
        _showBlocked(msg);
      } else if (code == 403) {
        _err(msg.isNotEmpty ? msg : 'Buy sats is only available in Tanzania');
      } else if (code == 429) {
        _err(msg.isNotEmpty ? msg : 'Daily limit reached. Try again tomorrow');
      } else if (code == 400) {
        _err(msg.isNotEmpty ? msg : 'Invalid request');
      } else if (code == 503) {
        _err('Cannot fetch BTC price. Try again shortly');
      } else {
        _err(msg.isNotEmpty ? msg : 'Quote failed');
      }
    }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _sendBuySats() async {
    final bolt11 = _bolt.text.trim();
    if (bolt11.isEmpty || !bolt11.startsWith('lnbc')) {
      _err('Enter valid BOLT11 invoice');
      return;
    }

    setState(() { _busy = true; });
    try {
      final r = await _api.sendSats(qid: _q!['quoteId'], bolt11: bolt11);
      if (r['success'] == true || r['status'] == 'ussd_sent' || r['selcomOrderId'] != null) {
        final orderId = r['selcomOrderId'] ?? r['orderId'] ?? '';

        setState(() {
          _step = _Step.processing;
          _busy = false;
          _phase = 0;
          _failed = false;
          _failMsg = '';
        });

        if (orderId.toString().isNotEmpty) {
          _pollBuyStatus(orderId.toString());
        }
      } else {
        final error = r['error'] ?? 'Payment failed';
        _err(error.toString());
        setState(() => _busy = false);
      }
    } catch (e) {
      final code = _statusCode(e);
      final msg = _extractError(e, '');

      if (code == 409) {
        _err(msg.isNotEmpty ? msg : 'Invoice conflict — generate a new one');
      } else if (code == 410) {
        _err('Quote expired. Please start over');
        Future.delayed(const Duration(seconds: 2), _reset);
      } else if (code == 400) {
        _err(msg.isNotEmpty ? msg : 'Invalid BOLT11 invoice');
      } else if (code == 429) {
        _err(msg.isNotEmpty ? msg : 'Daily buy limit reached (10 per day)');
      } else if (code == 502) {
        _err('Mobile money payment failed to initiate. Try again');
      } else {
        _err(msg.isNotEmpty ? msg : 'Failed — check your BOLT11 invoice');
      }
      setState(() => _busy = false);
    }
  }

  void _pollBuyStatus(String orderId) {
    _poll?.cancel();
    int attempts = 0;
    final maxAttempts = 150; // ~10 min at 4s intervals
    _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
      attempts++;
      if (!mounted || attempts > maxAttempts) {
        t.cancel();
        if (mounted) setState(() { _failed = true; _failMsg = 'Muda umeisha — angalia history baadaye'; });
        return;
      }
      try {
        final r = await _api.buyStatus(orderId);
        final status = (r['status'] ?? '').toString();

        if (status == 'sats_sent' || status == 'completed') {
          t.cancel();
          final sats = r['satsSent'] ?? _q?['calculatedSats'] ?? 0;
          if (mounted) setState(() {
            _satsSent = sats is int ? sats : int.tryParse(sats.toString()) ?? 0;
            _phase = 2;
          });
          Future.delayed(const Duration(milliseconds: 500), _showSuccess);
        } else if (status == 'payment_received') {
          if (mounted && _phase < 1) setState(() => _phase = 1);
        } else if (status == 'payment_failed' || status == 'cancelled' || status == 'selcom_failed') {
          t.cancel();
          if (mounted) setState(() { _failed = true; _failMsg = r['message']?.toString() ?? 'Malipo yameshindwa'; });
        } else if (status == 'payout_failed') {
          t.cancel();
          if (mounted) setState(() {
            _failed = true;
            _failMsg = 'Payment received but sats delivery failed. Contact support@chapsmart.com with order: $orderId';
          });
        }
      } catch (_) {}
    });
  }

  void _showSuccess() {
    final sats = _satsSent ?? _q?['calculatedSats'] ?? 0;
    SuccessSheet.show(context,
      title: 'Sats Zimetumwa!',
      message: '$sats sats sent to your Lightning wallet.',
      detail: 'M-Pesa → Bitcoin complete',
      icon: Icons.flash_on_rounded, color: C.green,
      buttonLabel: 'Buy More', onButton: () { Navigator.pop(context); _reset(); },
      secondaryLabel: 'Back to Home', onSecondary: () { Navigator.pop(context); Navigator.pop(context); },
    );
  }

  void _showBlocked(String msg) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: C.red.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.block_rounded, color: C.red, size: 24)),
          const SizedBox(height: 12),
          const Text('Akaunti Imezuiwa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(fontSize: 13, color: C.t2, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Btn(label: 'Rudi Nyumbani', onTap: () { Navigator.pop(context); Navigator.pop(context); }, icon: Icons.home_rounded),
          const SizedBox(height: 16),
        ]),
      ));
  }

  void _reset() {
    _poll?.cancel();
    setState(() {
      _step = _Step.form;
      _q = null;
      _busy = false;
      _bolt.clear();
      _amt.clear();
      _phase = 0;
      _failed = false;
      _failMsg = '';
      _satsSent = null;
    });
  }

  void _err(String m) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.red)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _Step.form ? 'Buy Sats' : _step == _Step.quoteAndBolt11 ? 'Confirm & Pay' : 'Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == _Step.quoteAndBolt11) setState(() => _step = _Step.form);
            else if (_step == _Step.processing && _failed) _reset();
            else if (_step == _Step.form) Navigator.pop(context);
            // Don't allow back during active payment
          },
        ),
      ),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _body())),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.form: return _buildStep1();
      case _Step.quoteAndBolt11: return _buildStep2();
      case _Step.processing: return _buildStep3();
    }
  }

  /// Step 1: Amount + Phone Number
  Widget _buildStep1() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Amount
      const Text('Amount (TZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _amt,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono'),
        decoration: const InputDecoration(prefixText: 'TZS ', hintText: '10000'),
        validator: (v) {
          final n = int.tryParse(v?.replaceAll(',', '') ?? '');
          return (n == null || n < K.buyMin || n > K.buyMax) ? 'Min ${K.buyMin} — Max ${K.buyMax} TZS' : null;
        },
      ),
      const SizedBox(height: 4),
      Text('Min ${Fmt.compact(K.buyMin)} — Max ${Fmt.compact(K.buyMax)} TZS', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 20),

      // Phone Number — all networks accepted
      const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        readOnly: _phoneLocked,
        style: TextStyle(fontSize: 15, color: _phoneLocked ? C.t2 : C.t1),
        decoration: InputDecoration(
          hintText: '0654xxxxxx',
          filled: true,
          fillColor: _phoneLocked ? C.bg : C.card,
        ),
        validator: (v) {
          if (_phoneLocked) return null;
          final raw = v?.trim() ?? '';
          if (raw.isEmpty || raw.length < 9) return 'Ingiza namba yako ya simu';
          return null;
        },
      ),
      const SizedBox(height: 4),
      if (_phoneLocked)
        Row(children: [
          Icon(Icons.lock_rounded, color: C.green, size: 12),
          const SizedBox(width: 4),
          const Text('Namba hii imefungwa na akaunti yako', style: TextStyle(fontSize: 11, color: C.green)),
        ])
      else
        const Text('Namba yako ya simu — utapokea USSD prompt', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 28),

      Btn(label: 'Get Quote', onTap: _getQuote, loading: _busy, icon: Icons.arrow_forward_rounded),
    ])));
  }

  /// Step 2: Quote summary + BOLT11 input
  Widget _buildStep2() {
    final sats = _q!['calculatedSats'] ?? 0;
    final feeSats = _q!['feeSats'] ?? 0;
    final feePercent = _q!['feePercent'] ?? 0;
    final btcPrice = _q!['btcPrice'] ?? 0;
    final tzs = int.tryParse(_amt.text.replaceAll(',', '')) ?? 0;

    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Quote box
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Column(children: [
          _QR('You pay', '${Fmt.compact(tzs)} TZS', big: true),
          const Divider(height: 20, color: C.border),
          _QR('You receive', '$sats sats', mono: true, color: C.green),
          _QR('Fee', '$feeSats sats ($feePercent%)'),
          _QR('BTC Price', '\$${(btcPrice is num ? btcPrice : 0).toStringAsFixed(0)}'),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Phone', style: TextStyle(fontSize: 13, color: C.t2)),
            Row(children: [
              const Icon(Icons.lock_rounded, color: C.green, size: 11),
              const SizedBox(width: 4),
              Text(_phone.text.trim(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.t1)),
            ]),
          ]),
          const SizedBox(height: 4),
          _QR('Valid for', '30 minutes'),
        ])),
      const SizedBox(height: 14),

      // How it works box
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.green.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.green.withOpacity(0.12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.phone_android_rounded, color: C.green, size: 13),
            const SizedBox(width: 8),
            const Text('Jinsi inavyofanya kazi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.t1)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Utapokea USSD kwenye simu yako — bonyeza 1 kuthibitisha malipo. Sats zitaingia moja kwa moja kwenye wallet yako.',
            style: TextStyle(fontSize: 12, color: C.t2, height: 1.7),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // BOLT11 input
      const Text('Your BOLT11 Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _bolt,
        maxLines: 2,
        style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
        decoration: const InputDecoration(hintText: 'lnbc...'),
      ),
      const SizedBox(height: 4),
      Text('Generate in your Lightning wallet for exactly $sats sats', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 24),

      // Buttons
      Row(children: [
        Expanded(child: BtnSecondary(label: 'Edit', icon: Icons.arrow_back_rounded, onTap: () => setState(() => _step = _Step.form))),
        const SizedBox(width: 10),
        Expanded(child: Btn(label: 'Pay & Send', onTap: _sendBuySats, loading: _busy, icon: Icons.flash_on_rounded)),
      ]),
    ]));
  }

  /// Step 3: Inline StepTracker (like airtime) — shows quote summary + 3-step progress
  Widget _buildStep3() {
    final sats = _q!['calculatedSats'] ?? 0;
    final tzs = int.tryParse(_amt.text.replaceAll(',', '')) ?? 0;

    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary card (compact)
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _failed ? C.red.withOpacity(0.08) : _phase == 2 ? C.green.withOpacity(0.08) : C.btc.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(
              _failed ? Icons.close_rounded : _phase == 2 ? Icons.check_rounded : Icons.phone_android_rounded,
              color: _failed ? C.red : _phase == 2 ? C.green : C.btc,
              size: 28,
            )),
          ),
          const SizedBox(height: 12),
          Text('$sats sats', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: C.btc)),
          const SizedBox(height: 4),
          Text('${Fmt.compact(tzs)} TZS → ${_phone.text.trim()}', style: const TextStyle(fontSize: 12, color: C.t2)),
        ])),

      const SizedBox(height: 20),

      // StepTracker — same pattern as airtime
      StepTracker(steps: const [
        StepItem(title: 'Thibitisha kwenye simu', subtitle: 'Bonyeza 1 kukubali malipo', icon: Icons.phone_android_rounded, color: C.btc),
        StepItem(title: 'Malipo yamepokelewa', subtitle: 'Inatuma sats...', icon: Icons.check_rounded, color: C.btc),
        StepItem(title: 'Sats zimetumwa', subtitle: 'Imekamilika kwenye wallet yako', icon: Icons.check_circle_rounded, color: C.green),
      ], currentStep: _phase),

      // Error message (only on failure)
      if (_failed) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.red.withOpacity(0.15)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_rounded, color: C.red, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(_failMsg, style: const TextStyle(fontSize: 12, color: C.t2, height: 1.5))),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: BtnSecondary(label: 'Back to Home', icon: Icons.home_rounded, onTap: () => Navigator.pop(context))),
          const SizedBox(width: 10),
          Expanded(child: Btn(label: 'Try Again', icon: Icons.refresh_rounded, onTap: _reset)),
        ]),
      ],
    ]));
  }

  Widget _QR(String l, String v, {bool big = false, bool mono = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 13, color: C.t2)),
    Flexible(child: Text(v, style: TextStyle(fontSize: big ? 18 : 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'SpaceMono' : null, color: color ?? (big ? C.btc : C.t1)), textAlign: TextAlign.right)),
  ]));
}
