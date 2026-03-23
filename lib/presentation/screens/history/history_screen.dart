import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  final _s = const FlutterSecureStorage();
  final _api = Api();
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final a = await _s.read(key: K.kAccount) ?? '';
      final r = await _api.history(a);
      final list = (r['transactions'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() { _txs = list; _loading = false; });
    } catch (e) { setState(() { _error = '$e'; _loading = false; }); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _txs;
    return _txs.where((t) {
      final type = t['type'] ?? '';
      final status = t['status'] ?? t['payoutStatus'] ?? '';
      if (_filter == 'remittance' || _filter == 'airtime' || _filter == 'buy-sats' || _filter == 'merchant_payment') return type == _filter;
      if (_filter == 'settled') return status == 'settled' || status == 'SUCCESS' || status == 'completed';
      if (_filter == 'pending') return status == 'pending';
      return true;
    }).toList();
  }

  IconData _icon(String type) {
    switch (type) {
      case 'airtime': return Icons.phone_android_rounded;
      case 'buy-sats': return Icons.currency_bitcoin_rounded;
      case 'merchant_payment': return Icons.storefront_rounded;
      default: return Icons.send_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'airtime': return C.blue;
      case 'buy-sats': return C.green;
      case 'merchant_payment': return C.purple;
      default: return C.btc;
    }
  }

  String _label(String type) {
    switch (type) {
      case 'airtime': return 'Airtime';
      case 'buy-sats': return 'Buy Sats';
      case 'merchant_payment': return 'Merchant';
      default: return 'Remittance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History'), actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: _load),
      ]),
      body: SafeArea(child: Column(children: [
        // Filter chips
        if (_txs.isNotEmpty) Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
            _Chip('All', 'all', null),
            _Chip('Remittance', 'remittance', C.btc),
            _Chip('Airtime', 'airtime', C.blue),
            _Chip('Buy Sats', 'buy-sats', C.green),
            _Chip('Merchant', 'merchant_payment', C.purple),
          ])),
        ),
        Expanded(child: _buildBody()),
      ])),
    );
  }

  Widget _Chip(String label, String value, Color? color) {
    final active = _filter == value;
    final c = color ?? C.btc;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.08) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c.withOpacity(0.3) : C.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? c : C.t3)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: C.btc));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: C.red, size: 48),
      const SizedBox(height: 12),
      const Text('Failed to load', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.t1)),
      const SizedBox(height: 8),
      GestureDetector(onTap: _load, child: const Text('Try again', style: TextStyle(fontSize: 14, color: C.btc, fontWeight: FontWeight.w600))),
    ]));

    final list = _filtered;
    if (list.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: C.bg, shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, color: C.t3, size: 36)),
      const SizedBox(height: 16),
      const Text('No transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.t1)),
      const SizedBox(height: 4),
      const Text('Your history will appear here', style: TextStyle(fontSize: 13, color: C.t3)),
    ]));

    return RefreshIndicator(
      color: C.btc, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          final type = t['type'] ?? 'remittance';
          final status = t['status'] ?? t['payoutStatus'] ?? 'pending';
          final name = t['recipientName'] ?? t['merchantName'] ?? '';
          final phone = t['phoneNumber'] ?? '';
          final amount = t['amountTZS'] ?? t['amount'] ?? 0;
          return TxTile(
            title: name.isNotEmpty ? name : _label(type),
            detail: phone.isNotEmpty ? phone : type,
            amount: 'TZS ${Fmt.compact(amount)}',
            time: '',
            status: status,
            icon: _icon(type),
            color: _color(type),
          );
        },
      ),
    );
  }
}
