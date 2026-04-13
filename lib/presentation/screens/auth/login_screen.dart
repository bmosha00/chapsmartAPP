import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _s = const FlutterSecureStorage();
  final _api = Api();
  bool _loading = false;
  String _input = '';

  Future<void> _login() async {
    if (_input.length < 10) return;
    setState(() => _loading = true);
    try {
      final r = await _api.login(_input);
      // Sign in with Firebase to get ID Token for all future requests
      if (r['customToken'] != null) {
        await _api.signInWithCustomToken(r['customToken']);
        await _s.write(key: K.kToken, value: r['customToken']);
      }
      await _s.write(key: K.kAccount, value: _input);
      await _s.write(key: K.kAuth, value: 'account');
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Check your number.'), backgroundColor: C.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _add(String d) { if (_input.length >= 16) return; HapticFeedback.lightImpact(); setState(() => _input += d); }
  void _del() { if (_input.isEmpty) return; HapticFeedback.lightImpact(); setState(() => _input = _input.substring(0, _input.length - 1)); }

  String get _display {
    if (_input.isEmpty) return '';
    final b = StringBuffer();
    for (int i = 0; i < _input.length; i++) { if (i > 0 && i % 4 == 0) b.write('  '); b.write(_input[i]); }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _input.length >= 10;
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          BackBtn(onTap: () => context.go('/')),
          const SizedBox(height: 32),
          const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.t1, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Enter your account number', style: TextStyle(fontSize: 14, color: C.t3)),
          const SizedBox(height: 28),
          Container(
            height: 56, width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _input.isNotEmpty ? C.btc.withOpacity(0.3) : C.border, width: 1.5)),
            child: Align(alignment: Alignment.centerLeft, child: Text(
              _display.isEmpty ? '···· ···· ···· ····' : _display,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpaceMono', letterSpacing: 2, color: _input.isEmpty ? C.t3.withOpacity(0.5) : C.t1),
            )),
          ),
          const SizedBox(height: 20),
          Expanded(child: _Keypad(onDigit: _add, onDelete: _del)),
          const SizedBox(height: 12),
          Btn(label: 'Sign in', onTap: ok ? _login : null, loading: _loading, enabled: ok),
          const SizedBox(height: 12),
          Center(child: GestureDetector(onTap: () => context.go('/nostr'), child: const Text('Use Nostr instead', style: TextStyle(fontSize: 13, color: C.t3)))),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  const _Keypad({required this.onDigit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final gap = 8.0;
      final kw = (c.maxWidth - gap * 2) / 3;
      final kh = ((c.maxHeight - gap * 3) / 4).clamp(0.0, 58.0);
      Widget key(String d) => GestureDetector(
        onTap: () => onDigit(d),
        child: Container(width: kw, height: kh, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
          child: Center(child: Text(d, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: C.t1)))),
      );
      Widget empty() => SizedBox(width: kw, height: kh);
      Widget del() => GestureDetector(onTap: onDelete, child: SizedBox(width: kw, height: kh, child: const Center(child: Icon(Icons.backspace_outlined, color: C.t3, size: 22))));
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [key('1'), SizedBox(width: gap), key('2'), SizedBox(width: gap), key('3')]),
        SizedBox(height: gap),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [key('4'), SizedBox(width: gap), key('5'), SizedBox(width: gap), key('6')]),
        SizedBox(height: gap),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [key('7'), SizedBox(width: gap), key('8'), SizedBox(width: gap), key('9')]),
        SizedBox(height: gap),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [empty(), SizedBox(width: gap), key('0'), SizedBox(width: gap), del()]),
      ]);
    });
  }
}
