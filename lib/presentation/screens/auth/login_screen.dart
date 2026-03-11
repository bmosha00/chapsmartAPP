import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await _api.login(_ctrl.text.trim());
      await _storage.write(
          key: AppConstants.keyAccountNumber, value: _ctrl.text.trim());
      await _storage.write(key: AppConstants.keyAuthMethod, value: 'account');
      if (res['customToken'] != null) {
        await _storage.write(
            key: AppConstants.keyFirebaseToken, value: res['customToken']);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login failed. Check your account number.'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _BackButton(onTap: () => context.go('/')),
                const SizedBox(height: 32),

                Text('Sign In',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Enter your account number',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 14)),

                const SizedBox(height: 32),
                TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Account number',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Enter a valid account number';
                    }
                    return null;
                  },
                ),

                const Spacer(),

                GoldButton(
                    label: 'Sign In',
                    onTap: _login,
                    loading: _loading),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/nostr-login'),
                    child: Text('Sign in with Nostr instead',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}