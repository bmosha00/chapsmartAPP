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
  final _api = ApiService();

  String? _accountNumber;
  String? _nostrPubkey;
  String? _authMethod;
  UserStats? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _accountNumber = await _storage.read(key: AppConstants.keyAccountNumber);
      _nostrPubkey = await _storage.read(key: AppConstants.keyNostrPubkey);
      _authMethod = await _storage.read(key: AppConstants.keyAuthMethod);
      if (_accountNumber != null) {
        final res = await _api.getUserStats(_accountNumber!);
        setState(() { _stats = UserStats.fromJson(res); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) context.go('/');
  }

  void _showLinkNostrDialog() {
    final eventCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Link Nostr Key', style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Paste a NIP-98 signed event to link your Nostr identity to this account.',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(controller: eventCtrl, maxLines: 5,
            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(hintText: '{"id":"...","pubkey":"...","kind":27235,...}',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.textMuted))),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            final res = await _api.nostrLink(_accountNumber!, {'raw': eventCtrl.text.trim()});
            if (res['success'] == true) {
              await _storage.write(key: AppConstants.keyNostrPubkey, value: res['nostrPubkey']);
              setState(() => _nostrPubkey = res['nostrPubkey']);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nostr key linked!'), backgroundColor: AppColors.success));
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to link: $e'), backgroundColor: AppColors.error));
          }
        }, child: Text('Link', style: GoogleFonts.dmSans(color: AppColors.gold, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(22),
        child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : Column(children: [
          // Account card
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1200), Color(0xFF2A1E00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.gold.withOpacity(0.25))),
              child: Column(children: [
                Container(width: 68, height: 68, decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Center(child: Text('C', style: GoogleFonts.playfairDisplay(color: AppColors.background, fontSize: 30, fontWeight: FontWeight.w800)))),
                const SizedBox(height: 14),
                if (_stats != null) TierBadge(tier: _stats!.userTier),
                const SizedBox(height: 10),
                Text(_authMethod == 'nostr' ? 'Nostr Account' : 'Anonymous Account',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(_accountNumber ?? '—', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 2)),
                if (_nostrPubkey != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.key_rounded, color: Color(0xFF8B5CF6), size: 12),
                        const SizedBox(width: 4),
                        Text('Nostr: ${_nostrPubkey!.substring(0, 8)}...', style: GoogleFonts.dmSans(color: const Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w500)),
                      ])),
                ],
              ])),

          const SizedBox(height: 24),

          // Nostr Link button (if not linked)
          if (_nostrPubkey == null) ...[
            GestureDetector(onTap: _showLinkNostrDialog, child: Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.06), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2))),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.link_rounded, color: Color(0xFF8B5CF6), size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Connect Nostr', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Link your Nostr key for easy login', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                ]))),
            const SizedBox(height: 24),
          ],

          // Stats grid
          if (_stats != null) ...[
            Row(children: [
              Expanded(child: StatsCard(label: 'Fee Rate', value: CurrencyFormatter.percent(_stats!.feePercent), icon: Icons.percent_rounded, accentColor: AppColors.gold)),
              const SizedBox(width: 12),
              Expanded(child: StatsCard(label: 'Transactions', value: '${_stats!.totalTransactions}', icon: Icons.receipt_long_rounded, accentColor: AppColors.info)),
            ]),
            const SizedBox(height: 12),
            StatsCard(label: 'Cumulative Spend', value: CurrencyFormatter.tzs(_stats!.cumulativeAmount), icon: Icons.trending_up_rounded, accentColor: AppColors.success),
            const SizedBox(height: 24),

            // Tier progression
            SectionHeader(title: 'Tier Progress'),
            const SizedBox(height: 14),
            _TierProgress(tier: _stats!.userTier, cumulative: _stats!.cumulativeAmount),
            const SizedBox(height: 24),
          ],

          // Fee tiers
          SectionHeader(title: 'Fee Tiers'),
          const SizedBox(height: 12),
          ...[('BRONZE', 2.2, 'Entry level'), ('SILVER', 1.87, 'Regular sender'), ('GOLD', 1.32, 'Power user')]
              .map((t) => _TierRow(tier: t.$1, fee: t.$2, label: t.$3, current: _stats?.userTier == t.$1)),

          const SizedBox(height: 28),
          OutlinedButton.icon(onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: Text('Logout', style: GoogleFonts.dmSans(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), foregroundColor: AppColors.error)),
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
    final thresholds = {'BRONZE': 0.0, 'SILVER': 5000000.0, 'GOLD': 25000000.0};
    final nextTier = tier == 'GOLD' ? null : (tier == 'SILVER' ? 'GOLD' : 'SILVER');
    final nextThresh = nextTier != null ? thresholds[nextTier]! : thresholds['GOLD']!;
    final progress = (cumulative / nextThresh).clamp(0.0, 1.0);

    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TierBadge(tier: tier),
            if (nextTier != null) Text('Next: $nextTier', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.surfaceLight, valueColor: const AlwaysStoppedAnimation(AppColors.gold), minHeight: 6)),
          const SizedBox(height: 8),
          Text(tier == 'GOLD' ? 'Maximum tier achieved!' : '${(progress * 100).toStringAsFixed(0)}% to $nextTier',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
        ]));
  }
}

class _TierRow extends StatelessWidget {
  final String tier, label;
  final double fee;
  final bool current;
  const _TierRow({required this.tier, required this.fee, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: current ? AppColors.gold.withOpacity(0.06) : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: current ? AppColors.gold.withOpacity(0.3) : AppColors.border)),
        child: Row(children: [
          TierBadge(tier: tier), const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13))),
          Text('${fee.toStringAsFixed(2)}% fee', style: GoogleFonts.dmSans(color: current ? AppColors.gold : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          if (current) ...[const SizedBox(width: 6), const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 16)],
        ]));
  }
}