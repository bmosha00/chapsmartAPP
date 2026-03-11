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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  bool _loading = false;
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
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
      if (mounted) context.go('/home');
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

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Background gradient + pattern
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xFF060A14), Color(0xFF0A0E1A), Color(0xFF0D1525)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          )),
        )),

        // Gold accent circle
        Positioned(top: -80, right: -60,
          child: Container(width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.gold.withOpacity(0.12), Colors.transparent]),
            ),
          ),
        ),
        Positioned(bottom: 100, left: -40,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.gold.withOpacity(0.06), Colors.transparent]),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                const SizedBox(height: 60),

                // Logo
                const AppLogo(size: 64),
                const SizedBox(height: 20),

                // Brand
                Text('ChapSmart', style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                )),
                const SizedBox(height: 8),
                Text('Bitcoin → Mobile Money', style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 15, letterSpacing: 0.2,
                )),

                const SizedBox(height: 60),

                // Feature tiles
                ..._features.map((f) => _FeatureTile(icon: f.$1, title: f.$2, subtitle: f.$3)),

                const Spacer(),

                // CTA
                GoldButton(label: 'Create Account', onTap: _createAccount, loading: _loading, icon: Icons.rocket_launch_rounded),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: Text('I already have an account', style: GoogleFonts.dmSans(color: AppColors.gold)),
                ),
                const SizedBox(height: 32),

                Text('Anonymous • No KYC required', style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 12,
                )),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  static const _features = [
    (Icons.bolt_rounded,        'Lightning Fast',       'Send sats, receive TZS in minutes'),
    (Icons.phone_android_rounded,'Mobile Money Payout', 'M-Pesa, Tigo & Airtel supported'),
    (Icons.shield_rounded,      'Tiered Rewards',       'Lower fees as you transact more'),
  ];
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
          )),
          Text(subtitle, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ]),
    );
  }
}
