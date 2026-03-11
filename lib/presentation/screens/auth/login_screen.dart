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
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _api     = ApiService();
  bool _loading  = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await _api.login(_ctrl.text.trim());
      await _storage.write(key: AppConstants.keyAccountNumber, value: _ctrl.text.trim());
      if (res['customToken'] != null) {
        await _storage.write(key: AppConstants.keyFirebaseToken, value: res['customToken']);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login failed. Check your account number.'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(height: 40),
              const AppLogo(size: 52),
              const SizedBox(height: 20),
              Text('Welcome back', style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 8),
              Text('Enter your 16-digit account number to continue', style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 14,
              )),
              const SizedBox(height: 40),

              Text('Account Number', style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                maxLength: 16,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 18, letterSpacing: 2.5, fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.textMuted, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().length != 16) return 'Enter a valid 16-digit account number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Your account number was shown when you first created your account.',
                    style: GoogleFonts.dmSans(color: AppColors.info, fontSize: 12),
                  )),
                ]),
              ),

              const SizedBox(height: 32),
              GoldButton(label: 'Sign In', onTap: _login, loading: _loading, icon: Icons.login_rounded),
              const SizedBox(height: 20),
              Center(child: GestureDetector(
                onTap: () => context.go('/'),
                child: Text("Don't have an account? Create one →", style: GoogleFonts.dmSans(
                  color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500,
                )),
              )),
            ],
          )),
        ),
      ),
    );
  }
}
