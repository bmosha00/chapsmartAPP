import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  List<Transaction> _transactions = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final acc = await _storage.read(key: AppConstants.keyAccountNumber) ?? '';
      final res = await _api.getHistory(acc);
      final list = (res['transactions'] as List? ?? [])
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _transactions = list; _stats = res['stats']; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  List<Transaction> get _filtered {
    if (_filter == 'all') return _transactions;
    if (_filter == 'remittance' || _filter == 'airtime' || _filter == 'buy-sats') {
      return _transactions.where((t) => t.type == _filter).toList();
    }
    return _transactions.where((t) => t.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History'), actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)]),
      body: SafeArea(child: Column(children: [
        // Stats row
        if (_stats != null) Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
          Expanded(child: StatsCard(label: 'Total', value: '${_stats!['totalTransactions'] ?? _transactions.length}', icon: Icons.receipt_long_rounded)),
          const SizedBox(width: 12),
          Expanded(child: StatsCard(label: 'Settled', value: '${_transactions.where((t) => t.isSettled).length}', icon: Icons.check_circle_rounded, accentColor: AppColors.success)),
        ])),

        // Filter chips
        if (_transactions.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
          _Chip(label: 'All', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
          _Chip(label: 'Remittance', active: _filter == 'remittance', onTap: () => setState(() => _filter = 'remittance'), color: AppColors.remittanceColor),
          _Chip(label: 'Airtime', active: _filter == 'airtime', onTap: () => setState(() => _filter = 'airtime'), color: AppColors.airtimeColor),
          _Chip(label: 'Buy Sats', active: _filter == 'buy-sats', onTap: () => setState(() => _filter = 'buy-sats'), color: AppColors.buySatsColor),
          _Chip(label: 'Settled', active: _filter == 'settled', onTap: () => setState(() => _filter = 'settled')),
          _Chip(label: 'Pending', active: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
        ]))),

        Expanded(child: _buildBody()),
      ])),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
      const SizedBox(height: 12),
      Text('Failed to load history', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15)),
      const SizedBox(height: 8),
      TextButton(onPressed: _load, child: const Text('Try again')),
    ]));
    if (_filtered.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 36)),
      const SizedBox(height: 16),
      Text('No transactions yet', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Your transaction history will appear here', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
    ]));

    return RefreshIndicator(color: AppColors.gold, onRefresh: _load,
        child: ListView.builder(padding: const EdgeInsets.all(20), itemCount: _filtered.length, itemBuilder: (ctx, i) {
          final t = _filtered[i];
          return TransactionTile(recipientName: t.recipientName, phoneNumber: t.phoneNumber, amountTZS: t.amountTZS, sats: t.sats, status: t.status, type: t.type, date: t.createdAt);
        }));
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;
  const _Chip({required this.label, required this.active, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return GestureDetector(onTap: onTap, child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: active ? c.withOpacity(0.15) : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? c : AppColors.border)),
      child: Text(label, style: GoogleFonts.dmSans(color: active ? c : AppColors.textSecondary, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
    ));
  }
}