import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

enum _Step { form, quote, payment }

class RemittanceScreen extends StatefulWidget {
  const RemittanceScreen({super.key});
  @override
  State<RemittanceScreen> createState() => _S();
}

class _S extends State<RemittanceScreen> {
  final _fk = GlobalKey<FormState>();
  final _amt = TextEditingController(), _phone = TextEditingController(), _name = TextEditingController();
  final _s = const FlutterSecureStorage();
  final _api = Api();
  _Step _step = _Step.form;
  bool _busy = false;
  Map<String, dynamic>? _q, _inv;
  Timer? _poll;
  int _phase = 0;

  @override
  void dispose() { _poll?.cancel(); _amt.dispose(); _phone.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _getQuote() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final a = await _s.read(key: K.kAccount) ?? '';
      final r = await _api.remitQuote(tzs: int.parse(_amt.text.replaceAll(',', '')), phone: _phone.text.trim(), name: _name.text.trim(), acc: a);
      setState(() { _q = r; _step = _Step.quote; });
    } catch (_) { _err('Failed to get quote'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final r = await _api.remitGenerate(_q!['quoteId']);
      setState(() { _inv = r; _step = _Step.payment; _phase = 0; });
      _startPoll();
    } catch (_) { _err('Failed to generate invoice'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _startPoll() {
    _poll?.cancel();
    int attempts = 0;
    _poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      attempts++;
      if (!mounted || attempts > 120) { t.cancel(); return; }
      try {
        final r = await _api.remitStatus(_inv!['invoiceId']);
        final s = r['status'] ?? 'pending';
        if (s == 'settled' && _phase < 2) setState(() => _phase = 2);
        if (s == 'completed') { t.cancel(); setState(() => _phase = 3); Future.delayed(const Duration(milliseconds: 500), _showSuccess); }
        if (s == 'expired' || s == 'failed') t.cancel();
      } catch (_) {}
    });
  }

  void _showSuccess() {
    final tzs = _q?['recipientReceives']?['tzs'] ?? 0;
    SuccessSheet.show(context,
      title: 'Payment Complete!',
      message: '${Fmt.tzs(tzs is int ? tzs : 0)} has been delivered to ${_name.text.trim()} via M-Pesa.',
      detail: 'M-Pesa payment received',
      buttonLabel: 'Send Another', onButton: () { Navigator.pop(context); _reset(); },
      secondaryLabel: 'Back to Home', onSecondary: () { Navigator.pop(context); Navigator.pop(context); },
    );
  }

  void _reset() { _poll?.cancel(); setState(() { _step = _Step.form; _q = null; _inv = null; _phase = 0; _amt.clear(); _phone.clear(); _name.clear(); }); }
  void _err(String m) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.red)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == _Step.form ? 'Send to M-Pesa' : _step == _Step.quote ? 'Confirm' : 'Payment'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (_step == _Step.quote) setState(() => _step = _Step.form); else Navigator.pop(context); })),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _body())),
    );
  }

  Widget _body() { switch (_step) { case _Step.form: return _buildForm(); case _Step.quote: return _buildQuote(); case _Step.payment: return _buildPayment(); } }

  Widget _buildForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Amount (TZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _amt, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono'), decoration: const InputDecoration(prefixText: 'TZS ', hintText: '5000'),
        validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); return (n == null || n < K.remitMin || n > K.remitMax) ? 'Amount out of range' : null; }),
      const SizedBox(height: 4), Text('Min ${Fmt.compact(K.remitMin)} — Max ${Fmt.compact(K.remitMax)} TZS', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 16),
      const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '0741000000'), validator: (v) => (v == null || v.trim().length < 9) ? 'Valid M-Pesa number' : null),
      const SizedBox(height: 4), const Text('Vodacom M-Pesa numbers only', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 16),
      const Text('Recipient Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _name, decoration: const InputDecoration(hintText: 'Full name (first and last)'),
        validator: (v) => (v == null || v.trim().split(' ').where((w) => w.length >= 2).length < 2) ? 'First + last name required' : null),
      const SizedBox(height: 4), const Text('Must include first and last name', style: TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 28), Btn(label: 'Get Quote', onTap: _getQuote, loading: _busy, icon: Icons.arrow_forward_rounded),
    ])));
  }

  Widget _buildQuote() {
    final yp = _q!['youPay'] ?? {};
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Column(children: [
          _QR('Recipient gets', Fmt.tzs(_q!['recipientReceives']?['tzs'] ?? 0), big: true), const Divider(height: 20, color: C.border),
          _QR('You pay', Fmt.sats(yp['sats'] ?? 0), mono: true),
          _QR('Fee', '${Fmt.pct((yp['feePercent'] ?? 0).toDouble())} (${yp['feeSats'] ?? 0} sats)'),
          _QR('Tier', _q!['userTier'] ?? 'BRONZE'), _QR('To', _phone.text.trim()),
        ])),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: BtnSecondary(label: 'Edit', icon: Icons.arrow_back_rounded, onTap: () => setState(() => _step = _Step.form))),
        const SizedBox(width: 10),
        Expanded(child: Btn(label: 'Generate Invoice', onTap: _generate, loading: _busy, icon: Icons.flash_on_rounded)),
      ]),
    ]));
  }

  Widget _buildPayment() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: QrImageView(data: _inv!['bolt11'] ?? '', version: QrVersions.auto, size: 200)),
          const SizedBox(height: 16),
          Text(Fmt.sats(_inv!['youPay']?['sats'] ?? 0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: C.btc)),
        ])),
      const SizedBox(height: 12), CopyField(label: 'BOLT11 Invoice', value: _inv!['bolt11'] ?? ''),
      const SizedBox(height: 20),
      StepTracker(steps: const [
        StepItem(title: 'Waiting for payment', subtitle: 'Pay the Lightning invoice', icon: Icons.flash_on_rounded, color: C.btc),
        StepItem(title: 'Payment confirmed', subtitle: 'Bitcoin received', icon: Icons.check_rounded, color: C.btc),
        StepItem(title: 'Sending to M-Pesa', subtitle: 'Processing transfer', icon: Icons.send_rounded, color: C.blue),
        StepItem(title: 'Received on M-Pesa', subtitle: 'Delivered successfully', icon: Icons.check_circle_rounded, color: C.green),
      ], currentStep: _phase),
    ]));
  }

  Widget _QR(String l, String v, {bool big = false, bool mono = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 13, color: C.t2)),
    Text(v, style: TextStyle(fontSize: big ? 18 : 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'SpaceMono' : null, color: big ? C.btc : C.t1)),
  ]));
}
