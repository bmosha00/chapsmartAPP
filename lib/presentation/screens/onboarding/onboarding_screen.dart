import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _checking = true;
  final _s = const FlutterSecureStorage();
  final _api = Api();
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _check();
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  Future<void> _check() async {
    final a = await _s.read(key: K.kAccount);
    if (a != null && mounted) {
      context.go('/home');
    } else {
      if (mounted) setState(() => _checking = false);
      _ac.forward();
    }
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final r = await _api.createAccount();
      if (r['customToken'] != null) {
        await _api.signInWithCustomToken(r['customToken']);
        await _s.write(key: K.kToken, value: r['customToken']);
      }
      await _s.write(key: K.kAccount, value: r['accountNumber']);
      await _s.write(key: K.kAuth, value: 'account');
      if (mounted) _showSuccess(r['accountNumber']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create account. Please check your connection and try again.'),
            backgroundColor: C.red,
          ),
        );
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showSuccess(String acc) {
    showModalBottomSheet(
      context: context, isDismissible: false, enableDrag: false,
      backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _SuccessSheet(acc: acc, onGo: () { Navigator.pop(context); context.go('/home'); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: C.bg,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.btc, C.btcDark]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: C.btc.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
          ), child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 32)),
          const SizedBox(height: 20),
          RichText(text: const TextSpan(style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'DM Sans'), children: [
            TextSpan(text: 'Chap', style: TextStyle(color: C.t1)),
            TextSpan(text: 'Smart', style: TextStyle(color: C.btc)),
          ])),
          const SizedBox(height: 16),
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: C.btc, strokeWidth: 2)),
          const SizedBox(height: 12),
          const Text('Loading...', style: TextStyle(fontSize: 13, color: C.t3)),
        ])),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const Spacer(flex: 2),
              Container(width: 72, height: 72, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [C.btc, C.btcDark]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: C.btc.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
              ), child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 36)),
              const SizedBox(height: 28),
              RichText(text: const TextSpan(style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'DM Sans'), children: [
                TextSpan(text: 'Chap', style: TextStyle(color: C.t1)),
                TextSpan(text: 'Smart', style: TextStyle(color: C.btc)),
              ])),
              const SizedBox(height: 8),
              const Text('Bitcoin \u2194 Mobile Money', style: TextStyle(fontSize: 15, color: C.t3)),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Svc(Icons.send_rounded, 'Send', C.btc),
                const SizedBox(width: 28),
                _Svc(Icons.phone_android_rounded, 'Airtime', C.blue),
                const SizedBox(width: 28),
                _Svc(Icons.currency_bitcoin_rounded, 'Buy BTC', C.green),
                const SizedBox(width: 28),
                _Svc(Icons.storefront_rounded, 'Pay', C.purple),
              ]),
              const Spacer(flex: 3),
              Btn(label: 'Get started', onTap: _create, loading: _loading),
              const SizedBox(height: 10),
              BtnSecondary(label: 'I have an account', onTap: () => context.go('/login')),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.go('/nostr'),
                child: Container(height: 52, width: double.infinity, decoration: BoxDecoration(color: C.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.purple.withOpacity(0.15))),
                    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.key_rounded, color: C.purple, size: 16), const SizedBox(width: 8),
                      Text('Continue with Nostr', style: TextStyle(color: C.purple, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]))),
              ),
              const SizedBox(height: 20),
              const Text('No KYC \u00b7 No personal data', style: TextStyle(fontSize: 12, color: C.t3)),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Svc extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _Svc(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 22)),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: C.t3)),
    ]);
  }
}

class _SuccessSheet extends StatelessWidget {
  final String acc; final VoidCallback onGo;
  const _SuccessSheet({required this.acc, required this.onGo});
  String get _fmt { final b = StringBuffer(); for (int i = 0; i < acc.length; i++) { if (i > 0 && i % 4 == 0) b.write(' '); b.write(acc[i]); } return b.toString(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      decoration: const BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(width: 64, height: 64, decoration: BoxDecoration(color: C.green.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: C.green, size: 32)),
        const SizedBox(height: 16),
        const Text("You're all set", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.t1)),
        const SizedBox(height: 6),
        const Text('Save your account number', style: TextStyle(fontSize: 14, color: C.t3)),
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
            child: Column(children: [
              const Text('ACCOUNT NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.t3, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              SelectableText(_fmt, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: C.btc, letterSpacing: 2)),
            ])),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { Clipboard.setData(ClipboardData(text: acc)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), backgroundColor: C.t1, behavior: SnackBarBehavior.floating)); },
          child: Container(height: 44, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.copy_rounded, color: C.t3, size: 14), SizedBox(width: 6), Text('Copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.t3))])),
        ),
        const SizedBox(height: 24),
        Btn(label: 'Continue', onTap: onGo),
      ]),
    );
  }
}
