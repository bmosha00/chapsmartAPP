import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class NostrLoginScreen extends StatefulWidget {
  const NostrLoginScreen({super.key});
  @override
  State<NostrLoginScreen> createState() => _NostrLoginScreenState();
}

class _NostrLoginScreenState extends State<NostrLoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  final _eventCtrl = TextEditingController();
  bool _loading = false;
  bool _isSignup = false;

  Future<void> _nostrAuth() async {
    if (_eventCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Paste your NIP-98 signed event'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      Map<String, dynamic> res;
      if (_isSignup) {
        res = await _api.nostrSignup({'raw': _eventCtrl.text.trim()});
      } else {
        res = await _api.nostrLogin({'raw': _eventCtrl.text.trim()});
      }

      if (res['success'] == true) {
        await _storage.write(
            key: AppConstants.keyAccountNumber, value: res['accountNumber']);
        await _storage.write(
            key: AppConstants.keyNostrPubkey, value: res['nostrPubkey']);
        await _storage.write(key: AppConstants.keyAuthMethod, value: 'nostr');
        if (res['customToken'] != null) {
          await _storage.write(
              key: AppConstants.keyFirebaseToken, value: res['customToken']);
        }
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSignup
              ? 'Signup failed. Key may already be linked.'
              : 'Login failed. No account found.'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _eventCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/'),
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
              ),
              const SizedBox(height: 32),

              Text('Nostr',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Authenticate with your Nostr identity',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 14)),

              const SizedBox(height: 24),

              // Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  _Toggle(
                      label: 'Login',
                      active: !_isSignup,
                      onTap: () => setState(() => _isSignup = false)),
                  _Toggle(
                      label: 'Signup',
                      active: _isSignup,
                      onTap: () => setState(() => _isSignup = true)),
                ]),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: TextFormField(
                  controller: _eventCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Paste NIP-98 signed event JSON here...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 12),
                    alignLabelWithHint: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              GoldButton(
                label: _isSignup ? 'Create Account' : 'Sign In',
                onTap: _nostrAuth,
                loading: _loading,
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Use account number instead',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                    color: active ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ))),
        ),
      ),
    );
  }
}