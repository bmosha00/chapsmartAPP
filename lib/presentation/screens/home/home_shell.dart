import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../remittance/remittance_screen.dart';
import '../airtime/airtime_screen.dart';
import '../buysats/buysats_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _screens = const [_Dashboard(), HistoryScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: C.card, border: Border(top: BorderSide(color: C.border, width: 0.5))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Nav(Icons.home_rounded, 'Home', _i == 0, () => setState(() => _i = 0)),
            _Nav(Icons.receipt_long_rounded, 'History', _i == 1, () => setState(() => _i = 1)),
            _Nav(Icons.person_rounded, 'Profile', _i == 2, () => setState(() => _i = 2)),
          ]),
        )),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _Nav(this.icon, this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: SizedBox(width: 64, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: active ? C.btc : C.t3, size: 22),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? C.btcDark : C.t3)),
    ])));
  }
}

class _Dashboard extends StatefulWidget {
  const _Dashboard();
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final _s = const FlutterSecureStorage();
  final _api = Api();
  String _acc = '';
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentTx = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final a = await _s.read(key: K.kAccount) ?? '';
    setState(() => _acc = a);
    try { final r = await _api.stats(a); if (mounted) setState(() => _stats = r); } catch (_) {}
    try {
      final h = await _api.history(a);
      final list = (h['transactions'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _recentTx = list.take(5).toList());
    } catch (_) {}
  }

  void _push(Widget s) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => s));

  String get _greeting { final h = DateTime.now().hour; return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening'; }

  @override
  Widget build(BuildContext context) {
    final tier = _stats?['userTier'] ?? 'BRONZE';
    final fee = (_stats?['feePercent'] ?? 2.2).toDouble();
    final txCount = _stats?['totalTransactions'] ?? 0;
    final cumul = (_stats?['cumulativeAmount'] ?? 0).toDouble();

    // FIX 4: Calculate amount left to next tier
    final thresholds = {'BRONZE': 5000000.0, 'SILVER': 25000000.0, 'GOLD': double.infinity};
    final nextTierName = _stats?['nextTier'];
    final nextThresh = thresholds[tier] ?? 5000000.0;
    final amountLeft = (nextThresh - cumul).clamp(0.0, nextThresh);
    final progress = ((_stats?['progressPercent'] ?? 0) / 100).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      body: SafeArea(child: RefreshIndicator(color: C.btc, onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
          // FIX 5: Logo + brand
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/images/logo_small.png', width: 32, height: 32, fit: BoxFit.cover)),
              const SizedBox(width: 10),
              const Text('Chapsmart', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'DM Sans', color: C.t1)),
            ]),
            TierBadge(tier: tier),
          ]),
          const SizedBox(height: 24),
          Text(_greeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.t1, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () { if (_acc.isNotEmpty) { Clipboard.setData(ClipboardData(text: _acc)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account copied'), backgroundColor: C.t1, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); } },
            child: Text('Account: ${_acc.isNotEmpty ? "${_acc.substring(0, 4)} ···· ${_acc.substring(_acc.length - 4)}" : "—"}', style: const TextStyle(fontSize: 13, fontFamily: 'SpaceMono', color: C.t3)),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(children: [
            Expanded(child: StatCard(label: 'TOTAL SPENT', value: '${Fmt.compact(cumul)} TZS', valueColor: C.btc, sub: '$txCount txns')),
            const SizedBox(width: 8),
            Expanded(child: StatCard(label: 'FEE RATE', value: Fmt.pct(fee), valueColor: C.green, sub: tier)),
          ]),
          const SizedBox(height: 10),

          // FIX 4: Tier progress with amount left
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border), boxShadow: [C.shadow]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$tier Tier', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  nextTierName != null ? '${Fmt.compact(amountLeft)} TZS to $nextTierName' : 'Highest tier!',
                  style: const TextStyle(fontSize: 12, color: C.t3),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, backgroundColor: C.bg, valueColor: const AlwaysStoppedAnimation(C.btc), minHeight: 8)),
            ])),
          const SizedBox(height: 24),

          // Quick Actions — 3 columns
          const SecHead(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _QA(Icons.send_rounded, 'Send', 'BTC → M-Pesa', C.btc, () => _push(const RemittanceScreen()))),
            const SizedBox(width: 8),
            Expanded(child: _QA(Icons.phone_android_rounded, 'Airtime', 'BTC → Top Up', C.blue, () => _push(const AirtimeScreen()))),
            const SizedBox(width: 8),
            Expanded(child: _QA(Icons.currency_bitcoin_rounded, 'Buy Sats', 'M-Pesa → BTC', C.green, () => _push(const BuySatsScreen()))),
          ]),

          const SizedBox(height: 28),

          // FIX 1: Recent — show individual tx amount, not cumulative
          SecHead(title: 'Recent', action: 'Refresh', onAction: _load),
          const SizedBox(height: 12),
          if (_recentTx.isEmpty)
            Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
              child: const Column(children: [Icon(Icons.receipt_long_rounded, color: C.t3, size: 32), SizedBox(height: 8), Text('No transactions yet', style: TextStyle(fontSize: 14, color: C.t3))]))
          else ..._recentTx.map((t) {
            final type = t['type'] ?? 'remittance';
            final status = t['status'] ?? t['payoutStatus'] ?? 'pending';
            final name = t['recipientName'] ?? '';
            final phone = t['phoneNumber'] ?? '';
            // FIX 1: Use individual transaction amount, not cumulative
            final txAmount = t['amountTZS'] ?? t['amount'] ?? 0;
            IconData ic; Color cl; String lbl;
            switch (type) { case 'airtime': ic = Icons.phone_android_rounded; cl = C.blue; lbl = 'Airtime'; break; case 'buy-sats': ic = Icons.currency_bitcoin_rounded; cl = C.green; lbl = 'Buy Sats'; break; default: ic = Icons.send_rounded; cl = C.btc; lbl = 'Remittance'; }
            return TxTile(title: name.isNotEmpty ? name : lbl, detail: phone.isNotEmpty ? phone : type, amount: '${Fmt.compact(txAmount)} TZS', time: '', status: status, icon: ic, color: cl);
          }),
        ]),
      )),
    );
  }
}

class _QA extends StatelessWidget {
  final IconData icon; final String title, sub; final Color color; final VoidCallback onTap;
  const _QA(this.icon, this.title, this.sub, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border), boxShadow: [C.shadow]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 19)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.t1)),
        const SizedBox(height: 1),
        Text(sub, style: const TextStyle(fontSize: 9, color: C.t3), textAlign: TextAlign.center, maxLines: 1),
      ]),
    ));
  }
}
