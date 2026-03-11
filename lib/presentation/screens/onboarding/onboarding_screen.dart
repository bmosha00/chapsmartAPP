import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _loading = false;
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final acc = await _storage.read(key: AppConstants.keyAccountNumber);
    if (acc != null && mounted) context.go('/home');
  }

  Future<void> _createAccount() async {
    setState(() => _loading = true);
    try {
      final res = await _api.createAccount();
      final account = res['accountNumber'];
      await _storage.write(key: AppConstants.keyAccountNumber, value: account);
      await _storage.write(key: AppConstants.keyAuthMethod, value: 'account');
      if (mounted) _showAccountDialog(account);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create account: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAccountDialog(String accountNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Account Created',
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Save this number. You need it to log in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: SelectableText(accountNumber,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                )),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'Continue',
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/home');
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo — replace with your image
              const AppLogo(size: 80),
              const SizedBox(height: 24),

              Text('ChapSmart',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Text('Bitcoin ↔ Mobile Money',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  )),

              const Spacer(flex: 4),

              // Buttons
              GoldButton(
                label: 'Create Account',
                onTap: _createAccount,
                loading: _loading,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: Text('Sign In',
                    style: GoogleFonts.dmSans(color: AppColors.gold)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/nostr-login'),
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text('Sign in with Nostr',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF8B5CF6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('No KYC required',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}