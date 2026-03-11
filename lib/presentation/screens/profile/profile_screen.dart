import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _api     = ApiService();

  String? _accountNumber;
  UserStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _accountNumber = await _storage.read(key: AppConstants.keyAccountNumber);
      if (_accountNumber != null) {
        final res = await _api.getUserStats(_accountNumber!);
        setState(() { _stats = UserStats.fromJson(res); _loading = false; });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : Column(children: [

          // Account card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1200), Color(0xFF2A1E00)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.25)),
            ),
            child: Column(children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text('C', style: GoogleFonts.playfairDisplay(
                  color: AppColors.background, fontSize: 30, fontWeight: FontWeight.w800,
                ))),
              ),
              const SizedBox(height: 14),
              if (_stats != null) TierBadge(tier: _stats!.userTier),
              const SizedBox(height: 10),
              Text('Anonymous Account', style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.3,
              )),
              const SizedBox(height: 4),
              Text(_accountNumber ?? '—', style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 2,
              )),
            ]),
          ),

          const SizedBox(height: 24),

          // Stats grid
          if (_stats != null) ...[
            Row(children: [
              Expanded(child: StatsCard(
                label: 'Fee Rate',
                value: CurrencyFormatter.percent(_stats!.feePercent),
                icon: Icons.percent_rounded,
                accentColor: AppColors.gold,
              )),
              const SizedBox(width: 12),
              Expanded(child: StatsCard(
                label: 'Total Transactions',
                value: '${_stats!.totalTransactions}',
                icon: Icons.receipt_long_rounded,
                accentColor: AppColors.info,
              )),
            ]),
            const SizedBox(height: 12),
            StatsCard(
              label: 'Cumulative Spend',
              value: CurrencyFormatter.tzs(_stats!.cumulativeAmount),
              icon: Icons.trending_up_rounded,
              accentColor: AppColors.success,
            ),

            const SizedBox(height: 24),

            // Tier progression
            SectionHeader(title: 'Tier Progress'),
            const SizedBox(height: 14),
            _TierProgress(tier: _stats!.userTier, cumulative: _stats!.cumulativeAmount),

            const SizedBox(height: 24),
          ],

          // Fee info
          SectionHeader(title: 'Fee Tiers'),
          const SizedBox(height: 12),
          ...[
            ('BRONZE', 2.2,  'Entry level'),
            ('SILVER', 1.87, 'Regular sender'),
            ('GOLD',   1.32, 'Power user'),
          ].map((t) => _TierRow(tier: t.$1, fee: t.$2, label: t.$3, current: _stats?.userTier == t.$1)),

          const SizedBox(height: 28),

          // Logout
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            label: Text('Logout', style: GoogleFonts.dmSans(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
            ),
          ),
        ]),
      )),
    );
  }
}

class _TierProgress extends StatelessWidget {
  final String tier;
  final double cumulative;
  const _TierProgress({required this.tier, required this.cumulative});

  @override
  Widget build(BuildContext context) {
    final thresholds = {'BRONZE': 0.0, 'SILVER': 3000000.0, 'GOLD': 10000000.0};
    final nextTier   = tier == 'GOLD' ? null : (tier == 'SILVER' ? 'GOLD' : 'SILVER');
    final nextThresh = nextTier != null ? thresholds[nextTier]! : thresholds['GOLD']!;
    final progress   = (cumulative / nextThresh).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TierBadge(tier: tier),
          if (nextTier != null) Text('Next: $nextTier', style: GoogleFonts.dmSans(
            color: AppColors.textSecondary, fontSize: 12,
          )),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tier == 'GOLD'
              ? 'Maximum tier achieved!'
              : 'TZS ${_fmt(cumulative.toInt())} / ${_fmt(nextThresh.toInt())} to $nextTier',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11),
        ),
      ]),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _TierRow extends StatelessWidget {
  final String tier, label;
  final double fee;
  final bool current;
  const _TierRow({required this.tier, required this.fee, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: current ? AppColors.gold.withOpacity(0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? AppColors.gold.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(children: [
        TierBadge(tier: tier),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.dmSans(
          color: AppColors.textSecondary, fontSize: 13,
        ))),
        Text('${fee.toStringAsFixed(2)}% fee', style: GoogleFonts.dmSans(
          color: current ? AppColors.gold : AppColors.textPrimary,
          fontSize: 13, fontWeight: FontWeight.w600,
        )),
        if (current) ...[
          const SizedBox(width: 6),
          const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 16),
        ],
      ]),
    );
  }
}