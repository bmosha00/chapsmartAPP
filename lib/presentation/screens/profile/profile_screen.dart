import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fmt.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../terms/terms_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  final _s = const FlutterSecureStorage();
  final _api = Api();
  String? _acc, _nostr, _auth;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _acc = await _s.read(key: K.kAccount);
      _nostr = await _s.read(key: K.kNostr);
      _auth = await _s.read(key: K.kAuth);
      if (_acc != null) {
        final r = await _api.stats(_acc!);
        setState(() { _stats = r; _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _logout() async { await _api.signOut(); await _s.deleteAll(); if (mounted) context.go('/'); }

  Future<void> _deleteAccount() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(width: 56, height: 56, decoration: BoxDecoration(color: C.red.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.warning_rounded, color: C.red, size: 28)),
          const SizedBox(height: 16),
          const Text('Delete Account?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 8),
          const Text('This is permanent. Your account, transaction history, bound phone, and all data will be deleted. This cannot be undone.',
            style: TextStyle(fontSize: 13, color: C.t2, height: 1.6), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Btn(label: 'Delete Account', onTap: () => Navigator.pop(ctx, true), icon: Icons.delete_forever_rounded),
          const SizedBox(height: 10),
          BtnSecondary(label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deleteAccount();
      await _api.signOut();
      await _s.deleteAll();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted'), backgroundColor: C.green)); context.go('/'); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: C.red)); }
  }

  void _linkNostr() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Link Nostr Key', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 6),
          const Text('Paste a NIP-98 signed event to link your Nostr identity.', style: TextStyle(fontSize: 13, color: C.t3), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 5, style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono', color: C.t1),
            decoration: const InputDecoration(hintText: '{"id":"...","pubkey":"...","kind":27235,...}')),
          const SizedBox(height: 16),
          Btn(label: 'Link', onTap: () async {
            Navigator.pop(ctx);
            try {
              final r = await _api.nostrLink(_acc!, {'raw': ctrl.text.trim()});
              if (r['success'] == true) { await _s.write(key: K.kNostr, value: r['nostrPubkey']); setState(() => _nostr = r['nostrPubkey']);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nostr key linked!'), backgroundColor: C.green)); }
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: C.red)); }
          }),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: C.btc)));
    final tier = _stats?['userTier'] ?? 'BRONZE';
    final fee = (_stats?['feePercent'] ?? 2.2).toDouble();
    final txCount = _stats?['totalTransactions'] ?? 0;
    final cumul = (_stats?['cumulativeAmount'] ?? 0).toDouble();
    final progress = ((_stats?['progressPercent'] ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    final nextTier = _stats?['nextTier'];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
        // Account card
        Container(width: double.infinity, padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF8ED), Color(0xFFFFF1D6)]),
            borderRadius: BorderRadius.circular(18), border: Border.all(color: C.btc.withOpacity(0.15)), boxShadow: [C.shadowMd]),
          child: Column(children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.btc, C.btcDark]), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: C.btc.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]),
              child: const Center(child: Text('C', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 12), TierBadge(tier: tier), const SizedBox(height: 8),
            Text(_auth == 'nostr' ? 'Nostr Account' : 'Anonymous Account', style: const TextStyle(fontSize: 12, color: C.t3)),
            const SizedBox(height: 4),
            GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _acc ?? '')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), backgroundColor: C.t1, behavior: SnackBarBehavior.floating)); },
              child: Text(_acc ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono', color: C.t1, letterSpacing: 1.5))),
            if (_nostr != null) ...[const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: C.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.key_rounded, color: C.purple, size: 12), const SizedBox(width: 4), Text('${_nostr!.substring(0, 8)}...', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.purple))]))],
          ])),
        const SizedBox(height: 20),

        // Nostr link
        if (_nostr == null) ...[
          GestureDetector(onTap: _linkNostr, child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.purple.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.purple.withOpacity(0.12))),
            child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: C.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.link_rounded, color: C.purple, size: 18)), const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Connect Nostr', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.t1)), Text('Link your Nostr key for easy login', style: TextStyle(fontSize: 12, color: C.t3))])),
              const Icon(Icons.chevron_right_rounded, color: C.t3, size: 18)]))), const SizedBox(height: 20)],

        // Stats
        Row(children: [Expanded(child: StatCard(label: 'FEE RATE', value: Fmt.pct(fee), valueColor: C.green)), const SizedBox(width: 10), Expanded(child: StatCard(label: 'TRANSACTIONS', value: '$txCount', valueColor: C.blue))]),
        const SizedBox(height: 10), StatCard(label: 'TOTAL SPEND', value: Fmt.tzs(cumul), valueColor: C.btc), const SizedBox(height: 20),

        // Tier progress
        const SecHead(title: 'Tier Progress'), const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [TierBadge(tier: tier), if (nextTier != null) Text('Next: $nextTier', style: const TextStyle(fontSize: 12, color: C.t3))]),
            const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, backgroundColor: C.bg, valueColor: const AlwaysStoppedAnimation(C.btc), minHeight: 8)),
            const SizedBox(height: 8), Text(tier == 'GOLD' ? 'Maximum tier!' : '${(progress * 100).toStringAsFixed(0)}% to ${nextTier ?? "next"}', style: const TextStyle(fontSize: 11, color: C.t3))])),
        const SizedBox(height: 20),

        // Fee tiers
        const SecHead(title: 'Fee Tiers'), const SizedBox(height: 12),
        ...[('BRONZE', 2.2, 'Entry level'), ('SILVER', 1.87, 'Regular sender'), ('GOLD', 1.32, 'Power user')].map((t) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: tier == t.$1 ? C.btc.withOpacity(0.04) : C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: tier == t.$1 ? C.btc.withOpacity(0.2) : C.border)),
          child: Row(children: [TierBadge(tier: t.$1), const SizedBox(width: 12), Expanded(child: Text(t.$3, style: const TextStyle(fontSize: 13, color: C.t2))),
            Text('${t.$2.toStringAsFixed(2)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono', color: tier == t.$1 ? C.btc : C.t1)),
            if (tier == t.$1) ...[const SizedBox(width: 6), const Icon(Icons.check_circle_rounded, color: C.btc, size: 16)]]))),

        const SizedBox(height: 28),

        // Settings
        const SecHead(title: 'Settings'), const SizedBox(height: 12),
        _ST(icon: Icons.description_rounded, color: C.blue, title: 'Terms & Conditions', subtitle: 'Masharti ya matumizi', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
        _ST(icon: Icons.info_rounded, color: C.green, title: 'About ChapSmart', subtitle: 'Version ${K.appVersion}', onTap: _showAbout),
        const SizedBox(height: 20),

        // Sign out
        GestureDetector(onTap: _logout, child: Container(height: 52, width: double.infinity,
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: C.t2, size: 18), SizedBox(width: 8), Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.t2))]))),
        const SizedBox(height: 10),

        // Delete account
        GestureDetector(onTap: _deleteAccount, child: Container(height: 52, width: double.infinity,
          decoration: BoxDecoration(color: C.red.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.red.withOpacity(0.15))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_forever_rounded, color: C.red, size: 18), SizedBox(width: 8), Text('Delete Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.red))]))),
        const SizedBox(height: 16),
      ]))),
    );
  }

  void _showAbout() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.btc, C.btcDark]), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28)),
        const SizedBox(height: 14),
        RichText(text: const TextSpan(style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'DM Sans'), children: [
          TextSpan(text: 'Chap', style: TextStyle(color: C.t1)), TextSpan(text: 'Smart', style: TextStyle(color: C.btc))])),
        const SizedBox(height: 4), Text('Version ${K.appVersion}', style: const TextStyle(fontSize: 13, color: C.t3)),
        const SizedBox(height: 16), const Text('Bitcoin \u2194 Mobile Money for Tanzania', style: TextStyle(fontSize: 14, color: C.t2)),
        const SizedBox(height: 6), const Text('Moshi, Kilimanjaro', style: TextStyle(fontSize: 12, color: C.t3)),
        const SizedBox(height: 20),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.email_rounded, color: C.t3, size: 14), SizedBox(width: 6), Text(K.supportEmail, style: TextStyle(fontSize: 13, color: C.t2))]),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.language_rounded, color: C.t3, size: 14), SizedBox(width: 6), Text(K.website, style: TextStyle(fontSize: 13, color: C.t2))]),
        const SizedBox(height: 24), BtnSecondary(label: 'Close', onTap: () => Navigator.pop(context)),
      ]),
    ));
  }
}

class _ST extends StatelessWidget {
  final IconData icon; final Color color; final String title, subtitle; final VoidCallback onTap;
  const _ST({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.t1)), Text(subtitle, style: const TextStyle(fontSize: 12, color: C.t3))])),
        const Icon(Icons.chevron_right_rounded, color: C.t3, size: 18)])));
  }
}
