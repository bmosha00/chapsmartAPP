import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

enum _Step { form, quoteAndBolt11, waiting }

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

  // Status tracking
  String _statusText = 'Inasubiri uthibitisho...';
  String _statusIcon = 'waiting'; // waiting, received, done, failed, blocked
  int? _satsSent;

  @override
  void initState() { super.initState(); _loadBoundPhone(); }

  @override
  void dispose() { _poll?.cancel(); _amt.dispose(); _phone.dispose(); _bolt.dispose(); super.dispose(); }

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

  Future<void> _getQuote() async {
    if (!_fk.currentState!.validate()) return;

    // Validate phone
    final phoneRaw = _phone.text.trim();
    if (!_phoneLocked && (phoneRaw.isEmpty || phoneRaw.length < 9)) {
      _err('Ingiza namba ya M-Pesa');
      return;
    }

    // Normalize phone
    String phoneNumber = phoneRaw.replaceAll(RegExp(r'\s+'), '');
    if (phoneNumber.startsWith('0')) phoneNumber = '255${phoneNumber.substring(1)}';
    if (phoneNumber.startsWith('+')) phoneNumber = phoneNumber.substring(1);

    setState(() => _busy = true);
    try {
      final a = await _s.read(key: K.kAccount) ?? '';
      final r = await _api.buyQuote(tzs: int.parse(_amt.text.replaceAll(',', '')), acc: a, phone: _boundPhone ?? phoneNumber);

      // Cache bound phone
      final bp = r['boundPhone'] as String?;
      if (bp != null && bp.isNotEmpty) {
        await _s.write(key: 'bound_phone', value: bp);
        setState(() {
          _boundPhone = bp;
          _phoneLocked = true;
          final display = bp.startsWith('255') ? '0${bp.substring(3)}' : bp;
          _phone.text = display;
        });
      } else {
        // Phone was just bound by this quote
        await _s.write(key: 'bound_phone', value: phoneNumber);
        setState(() {
          _boundPhone = phoneNumber;
          _phoneLocked = true;
        });
      }

      setState(() { _q = r; _step = _Step.quoteAndBolt11; });
    } catch (e) {
      final msg = e.toString();
      // Security blocks — Gate 2 phone binding, Gate 3 device limit
      if (msg.contains('device') || msg.contains('linked to a different') ||
          msg.contains('already linked') || msg.contains('disabled') ||
          msg.contains('2 accounts')) {
        _showBlocked(msg);
      } else if (msg.contains('403')) {
        _err('Buy sats is only available in Tanzania');
      } else if (msg.contains('429')) {
        _err('Daily limit reached. Try again tomorrow');
      } else {
        _err('Quote failed');
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
          _step = _Step.waiting;
          _busy = false;
          _statusText = 'Inasubiri uthibitisho...';
          _statusIcon = 'waiting';
        });

        if (orderId.toString().isNotEmpty) {
          _pollBuyStatus(orderId.toString());
        }
      } else {
        // Security blocks
        final error = r['error'] ?? 'Payment failed';
        if (error.toString().contains('device') || error.toString().contains('linked') ||
            error.toString().contains('Daily buy limit')) {
          _showBlocked(error.toString());
        } else {
          _err(error.toString());
        }
        setState(() => _busy = false);
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('409')) {
        _err('This invoice was already used');
      } else if (msg.contains('400')) {
        _err('Invoice amount does not match quote');
      } else {
        _err('Failed \u2014 check your BOLT11 invoice');
      }
      setState(() => _busy = false);
    }
  }

  void _pollBuyStatus(String orderId) {
    _poll?.cancel();
    int attempts = 0;
    final maxAttempts = 120; // 10 min at 5s intervals
    _poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      attempts++;
      if (!mounted || attempts > maxAttempts) {
        t.cancel();
        if (mounted) setState(() { _statusText = 'Muda umeisha \u2014 angalia history baadaye'; _statusIcon = 'failed'; });
        return;
      }
      try {
        final r = await _api.buyStatus(orderId);
        final status = r['status'] ?? '';
        if (status == 'sats_sent') {
          t.cancel();
          final sats = r['satsSent'] ?? _q?['calculatedSats'] ?? 0;
          if (mounted) setState(() { _satsSent = sats is int ? sats : int.tryParse(sats.toString()) ?? 0; _statusIcon = 'done'; _statusText = 'Imekamilika'; });
          Future.delayed(const Duration(milliseconds: 500), _showSuccess);
        } else if (status == 'payment_received') {
          if (mounted) setState(() { _statusText = 'Malipo yamepokelewa \u2014 inatuma sats...'; _statusIcon = 'received'; });
        } else if (status == 'failed' || status == 'cancelled' || status == 'payment_failed') {
          t.cancel();
          if (mounted) setState(() { _statusText = r['message'] ?? 'Malipo yameshindwa'; _statusIcon = 'failed'; });
        } else if (status == 'payout_failed' || status == 'selcom_failed') {
          t.cancel();
          if (mounted) setState(() { _statusText = 'Payment received but sats delivery failed. Contact support@chapsmart.com with order: $orderId'; _statusIcon = 'failed'; });
        }
      } catch (_) {}
    });
  }

  void _showSuccess() {
    final sats = _satsSent ?? _q?['calculatedSats'] ?? 0;
    SuccessSheet.show(context,
      title: 'Sats Zimetumwa!',
      message: '$sats sats zimeingia kwenye wallet yako.',
      detail: 'Lightning payment complete',
      icon: Icons.flash_on_rounded, color: C.green,
      buttonLabel: 'Buy More', onButton: () { Navigator.pop(context); _reset(); },
      secondaryLabel: 'Back to Home', onSecondary: () { Navigator.pop(context); Navigator.pop(context); },
    );
  }

  void _showBlocked(String error) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(width: 64, height: 64, decoration: BoxDecoration(color: C.red.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.shield_rounded, color: C.red, size: 32)),
        const SizedBox(height: 16),
        Text('Imezuiliwa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.red)),
        const SizedBox(height: 8),
        Text(error, style: TextStyle(fontSize: 14, color: C.t2, height: 1.6), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        BtnSecondary(label: 'Funga', onTap: () => Navigator.pop(context)),
      ]),
    ));
  }

  void _reset() { _poll?.cancel(); setState(() { _step = _Step.form; _q = null; _satsSent = null; _statusIcon = 'waiting'; _statusText = 'Inasubiri uthibitisho...'; _amt.clear(); _bolt.clear(); }); }
  void _err(String m) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.red)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _Step.form ? 'Buy Sats' : _step == _Step.quoteAndBolt11 ? 'Confirm & Pay' : 'Processing...'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == _Step.quoteAndBolt11) setState(() => _step = _Step.form);
            else if (_step != _Step.waiting || _statusIcon == 'failed') Navigator.pop(context);
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
      case _Step.waiting: return _buildStep3();
    }
  }

  /// Step 1: Amount + Phone Number
  Widget _buildStep1() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Amount
      Text('Amount (TZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _amt,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono'),
        decoration: const InputDecoration(prefixText: 'TZS ', hintText: '3000'),
        validator: (v) {
          final n = int.tryParse(v?.replaceAll(',', '') ?? '');
          return (n == null || n < K.buyMin || n > K.buyMax) ? 'Out of range' : null;
        },
      ),
      const SizedBox(height: 4),
      Text('Min ${Fmt.compact(K.buyMin)} \u2014 Max ${Fmt.compact(K.buyMax)} TZS', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 20),

      // Phone Number
      Text('Phone Number (M-Pesa)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        readOnly: _phoneLocked,
        style: TextStyle(fontSize: 15, color: _phoneLocked ? C.t2 : C.t1),
        decoration: InputDecoration(
          hintText: '0741000000',
          filled: true,
          fillColor: _phoneLocked ? C.bg : C.card,
        ),
      ),
      const SizedBox(height: 4),
      if (_phoneLocked)
        Row(children: [
          Icon(Icons.lock_rounded, color: C.green, size: 12),
          const SizedBox(width: 4),
          Text('Namba hii imefungwa na akaunti yako', style: TextStyle(fontSize: 11, color: C.green)),
        ])
      else
        Text('Namba yako ya M-Pesa \u2014 utapokea USSD prompt', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 28),

      Btn(label: 'Get Quote', onTap: _getQuote, loading: _busy, icon: Icons.arrow_forward_rounded),
    ])));
  }

  /// Step 2: Quote summary + BOLT11 input
  Widget _buildStep2() {
    final sats = _q!['calculatedSats'] ?? 0;
    final btcPrice = _q!['btcPrice'] ?? 0;
    final tzs = int.tryParse(_amt.text.replaceAll(',', '')) ?? 0;

    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Quote box
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Column(children: [
          _QR('You pay', '${Fmt.compact(tzs)} TZS', big: true),
          Divider(height: 20, color: C.border),
          _QR('You receive', '$sats sats', mono: true, color: C.green),
          _QR('BTC Price', '\$${(btcPrice is num ? btcPrice : 0).toStringAsFixed(0)}'),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Phone', style: TextStyle(fontSize: 13, color: C.t2)),
            Row(children: [
              const Icon(Icons.lock_rounded, color: C.green, size: 11),
              const SizedBox(width: 4),
              Text(_phone.text.trim(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.t1)),
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
            Text('Jinsi inavyofanya kazi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.t1)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Utapokea USSD kwenye simu yako \u2014 bonyeza 1 kuthibitisha malipo. Sats zitaingia moja kwa moja kwenye wallet yako.',
            style: TextStyle(fontSize: 12, color: C.t2, height: 1.7),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // BOLT11 input
      Text('Your BOLT11 Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _bolt,
        maxLines: 2,
        style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
        decoration: const InputDecoration(hintText: 'lnbc...'),
      ),
      const SizedBox(height: 4),
      Text('Generate in your Lightning wallet for exactly $sats sats', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 24),

      // Buttons
      Row(children: [
        Expanded(child: BtnSecondary(label: 'Edit', icon: Icons.arrow_back_rounded, onTap: () => setState(() => _step = _Step.form))),
        const SizedBox(width: 10),
        Expanded(child: Btn(label: 'Pay & Send', onTap: _sendBuySats, loading: _busy, icon: Icons.flash_on_rounded)),
      ]),
    ]));
  }

  /// Step 3: USSD waiting / result
  Widget _buildStep3() {
    final phoneDisplay = _phone.text.trim();
    final amt = int.tryParse(_amt.text.replaceAll(',', '')) ?? 0;

    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      const SizedBox(height: 40),
      // Status icon
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: _statusIcon == 'done' ? C.green.withOpacity(0.08) :
                 _statusIcon == 'failed' ? C.red.withOpacity(0.08) :
                 C.btc.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Center(child: _statusIcon == 'done'
          ? const Icon(Icons.check_rounded, color: C.green, size: 32)
          : _statusIcon == 'failed'
          ? const Icon(Icons.close_rounded, color: C.red, size: 32)
          : const Icon(Icons.phone_android_rounded, color: C.btc, size: 28)),
      ),
      const SizedBox(height: 16),

      // Title based on status
      Text(
        _statusIcon == 'done' ? 'Sats Zimetumwa!' :
        _statusIcon == 'failed' ? 'Imeshindwa' :
        _statusIcon == 'received' ? 'Malipo Yamepokelewa' :
        'Thibitisha kwenye simu yako',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _statusIcon == 'failed' ? C.red : C.t1),
      ),
      const SizedBox(height: 6),

      if (_statusIcon == 'done' && _satsSent != null)
        Text('${_satsSent!.toLocaleString()} sats zimeingia kwenye wallet yako', style: TextStyle(fontSize: 14, color: C.t2))
      else if (_statusIcon == 'waiting')
        Column(children: [
          Text('USSD prompt imetumwa kwa $phoneDisplay', style: TextStyle(fontSize: 13, color: C.t2)),
          const SizedBox(height: 8),
          Text('Bonyeza 1 kuthibitisha malipo ya ${Fmt.compact(amt)} TZS', style: TextStyle(fontSize: 12, color: C.t3)),
        ])
      else if (_statusIcon == 'received')
        Text('Inatuma sats kwenye wallet yako...', style: TextStyle(fontSize: 13, color: C.t2))
      else if (_statusIcon == 'failed')
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_statusText, style: TextStyle(fontSize: 13, color: C.t2, height: 1.5), textAlign: TextAlign.center),
        ),

      const SizedBox(height: 24),

      // Animated status indicator
      if (_statusIcon != 'done' && _statusIcon != 'failed')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: C.btc.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: C.btc)),
            const SizedBox(width: 8),
            Text(_statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.btc)),
          ]),
        )
      else if (_statusIcon == 'done')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: C.green.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded, color: C.green, size: 14),
            SizedBox(width: 8),
            Text('Imekamilika', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.green)),
          ]),
        )
      else if (_statusIcon == 'failed')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: C.red.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_rounded, color: C.red, size: 14),
            SizedBox(width: 8),
            Text('Imeshindwa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.red)),
          ]),
        ),

      const SizedBox(height: 40),

      // Action buttons on failure
      if (_statusIcon == 'failed') ...[
        Btn(label: 'Try Again', onTap: _reset, icon: Icons.refresh_rounded),
        const SizedBox(height: 10),
        BtnSecondary(label: 'Back to Home', onTap: () => Navigator.pop(context)),
      ],
    ]));
  }

  Widget _QR(String l, String v, {bool big = false, bool mono = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: TextStyle(fontSize: 13, color: C.t2)),
    Flexible(child: Text(v, style: TextStyle(fontSize: big ? 18 : 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'SpaceMono' : null, color: color ?? (big ? C.btc : C.t1)), textAlign: TextAlign.right)),
  ]));
}

extension on int {
  String toLocaleString() => toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
