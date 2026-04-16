import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class NostrLoginScreen extends StatefulWidget {
  const NostrLoginScreen({super.key});
  @override
  State<NostrLoginScreen> createState() => _NostrState();
}

class _NostrState extends State<NostrLoginScreen> {
  final _s = const FlutterSecureStorage();
  final _api = Api();
  final _ctrl = TextEditingController();
  bool _loading = false, _signup = false;

  Future<void> _go() async {
    if (_ctrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paste NIP-98 event'), backgroundColor: C.red)); return; }
    setState(() => _loading = true);
    try {
      final r = _signup ? await _api.nostrSignup({'raw': _ctrl.text.trim()}) : await _api.nostrLogin({'raw': _ctrl.text.trim()});
      if (r['success'] == true) {
        // Sign in with Firebase to get ID Token for all future requests
        if (r['customToken'] != null) {
          await _api.signInWithCustomToken(r['customToken']);
          await _s.write(key: K.kToken, value: r['customToken']);
        }
        await _s.write(key: K.kAccount, value: r['accountNumber']);
        await _s.write(key: K.kNostr, value: r['nostrPubkey']);
        await _s.write(key: K.kAuth, value: 'nostr');
        if (mounted) context.go('/home');
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_signup ? 'Signup failed' : 'Login failed'), backgroundColor: C.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          BackBtn(onTap: () => context.go('/')),
          const SizedBox(height: 32),
          Container(width: 48, height: 48, decoration: BoxDecoration(color: C.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.key_rounded, color: C.purple, size: 22)),
          const SizedBox(height: 16),
          Text('Nostr identity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 4),
          Text('Authenticate with your Nostr keys', style: TextStyle(fontSize: 14, color: C.t3)),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _Tab('Sign in', !_signup, () => setState(() => _signup = false)),
              _Tab('Create account', _signup, () => setState(() => _signup = true)),
            ])),
          const SizedBox(height: 16),
          Expanded(child: TextFormField(
            controller: _ctrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
            style: TextStyle(fontSize: 13, fontFamily: 'SpaceMono', color: C.t1, height: 1.5),
            decoration: const InputDecoration(hintText: 'Paste NIP-98 signed event JSON...', alignLabelWithHint: true),
          )),
          const SizedBox(height: 16),
          Btn(label: _signup ? 'Create account' : 'Sign in', onTap: _go, loading: _loading),
          const SizedBox(height: 12),
          Center(child: GestureDetector(onTap: () => context.go('/login'), child: Text('Use account number', style: TextStyle(fontSize: 13, color: C.t3)))),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _Tab(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: active ? C.card : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: active ? [C.shadow] : null),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? C.t1 : C.t3))),
    )));
  }
}
