import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

enum _Step { form, payment }

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});
  @override
  State<MerchantScreen> createState() => _S();
}

class _S extends State<MerchantScreen> {
  final _fk = GlobalKey<FormState>();
  final _mid = TextEditingController(), _amt = TextEditingController();
  final _api = Api();
  _Step _step = _Step.form;
  bool _busy = false, _lookingUp = false;
  String? _merchName;
  String? _merchId; // Store the actual merchantId from API
  Map<String, dynamic>? _inv;
  Timer? _poll;
  int _phase = 0;

  @override
  void dispose() { _poll?.cancel(); _mid.dispose(); _amt.dispose(); super.dispose(); }

  Future<void> _lookup() async {
    if (_mid.text.trim().isEmpty) return;
    setState(() { _lookingUp = true; _merchName = null; _merchId = null; });
    try {
      final r = await _api.merchantInfo(_mid.text.trim());
      // API may return { merchantId, merchantName, ... } or { merchant: { ... } }
      final name = r['merchantName'] ?? r['merchant']?['merchantName'];
      final id = r['merchantId'] ?? r['merchant']?['merchantId'] ?? _mid.text.trim();
      setState(() { _merchName = name; _merchId = id; });
    } catch (_) { _err('Merchant not found'); }
    finally { if (mounted) setState(() => _lookingUp = false); }
  }

  Future<void> _pay() async {
    if (!_fk.currentState!.validate() || _merchId == null) return;
    setState(() => _busy = true);
    try {
      // Use the merchantId from the lookup, not user input
      final r = await _api.merchantPay(mid: _merchId!, tzs: int.parse(_amt.text.replaceAll(',', '')));
      setState(() { _inv = r; _step = _Step.payment; _phase = 0; });
      _startPoll();
    } catch (e) { _err('Payment failed: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _startPoll() {
    _poll?.cancel();
    int attempts = 0;
    final iid = _inv!['invoiceId'] ?? '';
    _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
      attempts++;
      if (!mounted || attempts > 150) { t.cancel(); return; }
      try {
        final r = await _api.merchantStatus(iid);
        final step = r['step'] ?? 'waiting';
        if (step == 'sending' && _phase < 1) setState(() => _phase = 1);
        if (step == 'completed') {
          t.cancel(); setState(() => _phase = 2);
          Future.delayed(const Duration(milliseconds: 500), _showSuccess);
        }
        if (r['status'] == 'expired') { t.cancel(); _err('Invoice expired'); }
        if (r['status'] == 'failed') { t.cancel(); _err('Payment failed'); }
      } catch (_) {}
    });
  }

  void _showSuccess() {
    final amount = _amt.text;
    SuccessSheet.show(context,
      title: 'Payment Delivered!',
      message: '$_merchName has received ${Fmt.tzs(int.tryParse(amount) ?? 0)} via M-Pesa.',
      detail: 'Merchant paid successfully',
      icon: Icons.storefront_rounded, color: C.green,
      buttonLabel: 'Pay Again', onButton: () { Navigator.pop(context); _reset(); },
      secondaryLabel: 'Back to Home', onSecondary: () { Navigator.pop(context); Navigator.pop(context); },
    );
  }

  void _reset() { _poll?.cancel(); setState(() { _step = _Step.form; _inv = null; _merchName = null; _merchId = null; _phase = 0; _mid.clear(); _amt.clear(); }); }
  void _err(String m) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.red, behavior: SnackBarBehavior.floating)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == _Step.form ? 'Pay Merchant' : 'Payment'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (_step == _Step.payment && _phase >= 2) _reset(); else Navigator.pop(context); })),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _body())),
    );
  }

  Widget _body() { switch (_step) { case _Step.form: return _buildForm(); case _Step.payment: return _buildPayment(); } }

  Widget _buildForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Merchant ID or Slug', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      Row(children: [
        Expanded(child: TextFormField(controller: _mid, style: const TextStyle(fontSize: 14, fontFamily: 'SpaceMono'),
          decoration: const InputDecoration(hintText: 'e.g. test-duka or mch_abc123'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          onFieldSubmitted: (_) => _lookup(),
        )),
        const SizedBox(width: 8),
        GestureDetector(onTap: _lookup, child: Container(height: 52, width: 52, decoration: BoxDecoration(color: C.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.purple.withOpacity(0.15))),
          child: Center(child: _lookingUp ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.purple)) : const Icon(Icons.search_rounded, color: C.purple, size: 20)))),
      ]),
      if (_merchName != null) ...[const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.green.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: C.green, size: 16), const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_merchName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.green)),
              if (_merchId != null) Text(_merchId!, style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono', color: C.t3)),
            ])),
          ]))],
      const SizedBox(height: 20),
      const Text('Amount (TZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _amt, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono'), decoration: const InputDecoration(prefixText: 'TZS ', hintText: '5000'),
        validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); return (n == null || n < K.merchMin || n > K.merchMax) ? 'Out of range' : null; }),
      const SizedBox(height: 4), Text('Min ${Fmt.compact(K.merchMin)} — Max ${Fmt.compact(K.merchMax)} TZS', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 28), Btn(label: 'Pay with Bitcoin', onTap: _merchId != null ? _pay : null, loading: _busy, enabled: _merchId != null, icon: Icons.flash_on_rounded),
    ])));
  }

  Widget _buildPayment() {
    final bolt11 = _inv?['bolt11'] ?? '';
    final sats = _inv?['satsAmount'] ?? _inv?['youPay']?['sats'] ?? 0;
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      if (_merchName != null) ...[Text('Paying $_merchName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 16)],
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(children: [
          if (bolt11.isNotEmpty) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: QrImageView(data: bolt11, version: QrVersions.auto, size: 200))
          else const Padding(padding: EdgeInsets.all(40), child: Text('No Lightning invoice', style: TextStyle(color: C.t3, fontSize: 13))),
          const SizedBox(height: 16),
          Text(Fmt.sats(sats), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: C.btc)),
          Text(Fmt.tzs(int.tryParse(_amt.text) ?? 0), style: const TextStyle(fontSize: 13, color: C.t3)),
        ])),
      if (bolt11.isNotEmpty) ...[const SizedBox(height: 12), CopyField(label: 'BOLT11', value: bolt11)],
      if (_inv?['checkoutLink'] != null) ...[
        const SizedBox(height: 8),
        Hint(text: 'You can also pay via BTCPay checkout', icon: Icons.open_in_new_rounded, color: C.btc),
      ],
      const SizedBox(height: 20),
      StepTracker(steps: const [
        StepItem(title: 'Waiting for payment', subtitle: 'Pay the Lightning invoice', icon: Icons.flash_on_rounded, color: C.btc),
        StepItem(title: 'Sending M-Pesa', subtitle: 'Transferring to merchant', icon: Icons.send_rounded, color: C.blue),
        StepItem(title: 'Merchant paid', subtitle: 'M-Pesa delivered', icon: Icons.check_circle_rounded, color: C.green),
      ], currentStep: _phase),
    ]));
  }
}
