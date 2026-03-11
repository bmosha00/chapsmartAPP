import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/models.dart';
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
  int _index = 0;

  final _screens = const [
    _DashboardTab(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: _index == 0,
                    onTap: () => setState(() => _index = 0)),
                _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'History',
                    active: _index == 1,
                    onTap: () => setState(() => _index = 1)),
                _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    active: _index == 2,
                    onTap: () => setState(() => _index = 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active ? AppColors.gold : AppColors.textMuted, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.dmSans(
                color: active ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ]),
      ),
    );
  }
}

// ─── Dashboard ───────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  UserStats? _stats;
  String _acc = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final acc =
          await _storage.read(key: AppConstants.keyAccountNumber) ?? '';
      setState(() => _acc = acc);
      final res = await _api.getUserStats(acc);
      if (mounted) setState(() => _stats = UserStats.fromJson(res));
    } catch (_) {}
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo — replace Image.asset with your logo
                  const AppLogo(size: 40),
                  if (_stats != null) TierBadge(tier: _stats!.userTier),
                ],
              ),

              const SizedBox(height: 24),

              // Account card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                        _acc.isNotEmpty
                            ? '${_acc.substring(0, 4)} •••• ${_acc.substring(_acc.length - 4)}'
                            : '••••',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Row(children: [
                      _Stat(
                          label: 'Fee',
                          value:
                          '${(_stats?.feePercent ?? 2.2).toStringAsFixed(1)}%'),
                      const SizedBox(width: 32),
                      _Stat(
                          label: 'Transactions',
                          value: '${_stats?.totalTransactions ?? 0}'),
                      const SizedBox(width: 32),
                      _Stat(
                          label: 'Tier',
                          value: _stats?.userTier ?? 'BRONZE'),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text('Services',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // Service cards
              _ServiceTile(
                icon: Icons.send_rounded,
                color: AppColors.remittanceColor,
                title: 'Send Money',
                subtitle: 'BTC → M-Pesa',
                onTap: () => _push(const RemittanceScreen()),
              ),
              const SizedBox(height: 10),
              _ServiceTile(
                icon: Icons.phone_android_rounded,
                color: AppColors.airtimeColor,
                title: 'Buy Airtime',
                subtitle: 'BTC → Airtime top-up',
                onTap: () => _push(const AirtimeScreen()),
              ),
              const SizedBox(height: 10),
              _ServiceTile(
                icon: Icons.currency_bitcoin_rounded,
                color: AppColors.buySatsColor,
                title: 'Buy Bitcoin',
                subtitle: 'M-Pesa → Lightning sats',
                onTap: () => _push(const BuySatsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }
}