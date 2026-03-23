import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

enum _Step { form, quoteAndSubmit, sending }

class BuySatsScreen extends StatefulWidget {
  const BuySatsScreen({super.key});
  @override
  State<BuySatsScreen> createState() => _S();
}

class _S extends State<BuySatsScreen> {
  final _fk = GlobalKey<FormState>();
  final _amt = TextEditingController(), _bolt = TextEditingController(), _mpesa = TextEditingController();
  final _s = const FlutterSecureStorage();
  final _api = Api();
  _Step _step = _Step.form;
  bool _busy = false;
  Map<String, dynamic>? _q;

  @override
  void dispose() { _amt.dispose(); _bolt.dispose(); _mpesa.dispose(); super.dispose(); }

  Future<void> _getQuote() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final a = await _s.read(key: K.kAccount) ?? '';
      final r = await _api.buyQuote(tzs: int.parse(_amt.text.replaceAll(',', '')), acc: a);
      setState(() { _q = r; _step = _Step.quoteAndSubmit; });
    } catch (_) { _err('Quote failed'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _send() async {
    if (_mpesa.text.trim().isEmpty) { _err('Enter M-Pesa ID'); return; }
    if (_bolt.text.trim().isEmpty || !_bolt.text.trim().startsWith('lnbc')) { _err('Enter valid BOLT11'); return; }
    setState(() { _busy = true; _step = _Step.sending; });
    try {
      final r = await _api.sendSats(qid: _q!['quoteId'], bolt11: _bolt.text.trim(), mpesaId: _mpesa.text.trim());
      final sats = r['satsSent'] ?? _q?['calculatedSats'] ?? 0;
      if (mounted) {
        setState(() => _busy = false);
        SuccessSheet.show(context,
          title: 'Sats Sent!',
          message: '$sats sats have been delivered to your Lightning wallet.',
          detail: 'Lightning payment complete',
          icon: Icons.flash_on_rounded, color: C.green,
          buttonLabel: 'Buy More', onButton: () { Navigator.pop(context); _reset(); },
          secondaryLabel: 'Back to Home', onSecondary: () { Navigator.pop(context); Navigator.pop(context); },
        );
      }
    } catch (_) { _err('Failed — check details'); setState(() { _step = _Step.quoteAndSubmit; _busy = false; }); }
  }

  void _reset() { setState(() { _step = _Step.form; _q = null; _amt.clear(); _bolt.clear(); _mpesa.clear(); }); }
  void _err(String m) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.red)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == _Step.form ? 'Buy Sats' : _step == _Step.sending ? 'Sending...' : 'Pay & Claim'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (_step == _Step.quoteAndSubmit) setState(() => _step = _Step.form); else if (_step != _Step.sending) Navigator.pop(context); })),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _body())),
    );
  }

  Widget _body() {
    if (_step == _Step.sending) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: C.btc), SizedBox(height: 16),
      Text('Sending sats...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.t1)),
      SizedBox(height: 6), Text('This may take a few seconds', style: TextStyle(fontSize: 13, color: C.t3)),
    ]));
    switch (_step) { case _Step.form: return _buildForm(); case _Step.quoteAndSubmit: return _buildQS(); default: return const SizedBox(); }
  }

  Widget _buildForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Amount (TZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _amt, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono'), decoration: const InputDecoration(prefixText: 'TZS ', hintText: '3000'),
        validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); return (n == null || n < K.buyMin || n > K.buyMax) ? 'Out of range' : null; }),
      const SizedBox(height: 4), Text('Min ${Fmt.compact(K.buyMin)} — Max ${Fmt.compact(K.buyMax)} TZS', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 28), Btn(label: 'Get Quote', onTap: _getQuote, loading: _busy, icon: Icons.arrow_forward_rounded),
    ])));
  }

  Widget _buildQS() {
    final sats = _q!['calculatedSats'] ?? 0;
    final tzs = _q!['amountTZS'] ?? 0;
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Column(children: [
          _QR('You pay', '${Fmt.compact(tzs)} TZS', big: true), const Divider(height: 20, color: C.border),
          _QR('You receive', '$sats sats', mono: true, color: C.green),
          _QR('BTC Price', Fmt.usd(_q!['btcPrice'] ?? 0)), _QR('Valid for', '30 minutes'),
        ])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.green.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.green.withOpacity(0.12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.phone_android_rounded, color: C.green, size: 16)), const SizedBox(width: 8), const Text('KUTOA M-Pesa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 12),
          _MS(1, 'Piga *150*00#'), _MS(2, 'Chagua 2 – Kutoa Pesa'), _MS(3, 'Weka namba ya wakala: ${K.mpesaAgent}'),
          _MS(4, 'Ingiza kiasi: ${Fmt.compact(tzs)} TZS'), _MS(5, 'Jina: BRIAN'), _MS(6, 'Weka namba yako ya siri na uthibitishe'),
        ])),
      const SizedBox(height: 16),
      const Text('M-Pesa Transaction ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _mpesa, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'SpaceMono'), decoration: const InputDecoration(hintText: 'e.g. XKR4MPT9QZN')),
      const SizedBox(height: 16),
      const Text('Your BOLT11 Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t2)), const SizedBox(height: 6),
      TextFormField(controller: _bolt, maxLines: 2, style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'), decoration: const InputDecoration(hintText: 'lnbc...')),
      const SizedBox(height: 4), Text('Generate for exactly $sats sats', style: const TextStyle(fontSize: 11, color: C.t3)),
      const SizedBox(height: 24), Btn(label: 'Send Sats', onTap: _send, loading: _busy, icon: Icons.flash_on_rounded),
    ]));
  }

  Widget _QR(String l, String v, {bool big = false, bool mono = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 13, color: C.t2)),
    Text(v, style: TextStyle(fontSize: big ? 18 : 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'SpaceMono' : null, color: color ?? (big ? C.btc : C.t1))),
  ]));

  Widget _MS(int n, String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 22, height: 22, decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(7)), child: Center(child: Text('$n', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
    const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: C.t2, height: 1.4))),
  ]));
}
