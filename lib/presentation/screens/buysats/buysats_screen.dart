import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

enum BuyStep { form, quote, verify, success }

class BuySatsScreen extends StatefulWidget {
  const BuySatsScreen({super.key});
  @override
  State<BuySatsScreen> createState() => _BuySatsScreenState();
}

class _BuySatsScreenState extends State<BuySatsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _bolt11Ctrl = TextEditingController();
  final _mpesaIdCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  BuyStep _step = BuyStep.form;
  bool _loading = false;
  BuyQuote? _quote;

  @override
  void dispose() { _amountCtrl.dispose(); _bolt11Ctrl.dispose(); _mpesaIdCtrl.dispose(); super.dispose(); }

  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final acc = await _storage.read(key: AppConstants.keyAccountNumber) ?? '';
      final res = await _api.createBuyQuote(amountTZS: int.parse(_amountCtrl.text.replaceAll(',', '')), accountNumber: acc);
      setState(() { _quote = BuyQuote.fromJson(res); _step = BuyStep.quote; });
    } catch (e) { _showError('Failed to create quote'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _sendSats() async {
    if (_bolt11Ctrl.text.trim().isEmpty || _mpesaIdCtrl.text.trim().isEmpty) {
      _showError('Please fill all fields'); return;
    }
    setState(() => _loading = true);
    try {
      await _api.sendSats(quoteId: _quote!.quoteId, bolt11: _bolt11Ctrl.text.trim(), mpesaId: _mpesaIdCtrl.text.trim());
      setState(() => _step = BuyStep.success);
    } catch (e) { _showError('Failed to send sats. Check details.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _reset() { setState(() { _step = BuyStep.form; _quote = null; _amountCtrl.clear(); _bolt11Ctrl.clear(); _mpesaIdCtrl.clear(); }); }
  void _showError(String msg) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == BuyStep.form ? 'Buy Bitcoin' : _step == BuyStep.quote ? 'Your Quote' : _step == BuyStep.verify ? 'Verify & Claim' : 'Success'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (_step != BuyStep.form) { setState(() => _step = BuyStep.form); } else { Navigator.of(context).pop(); } })),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildBody())),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case BuyStep.form: return _buildForm();
      case BuyStep.quote: return _buildQuote();
      case BuyStep.verify: return _buildVerify();
      case BuyStep.success: return _buildSuccess();
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.buySatsColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.buySatsColor.withOpacity(0.2))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.buySatsColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.currency_bitcoin_rounded, color: AppColors.buySatsColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TZS → Lightning Sats', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Pay M-Pesa, receive sats to your wallet', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          ])),
      const SizedBox(height: 24),
      Text('Amount (TZS)', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(prefixText: 'TZS ', hintText: '0'),
          validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); if (n == null || n < AppConstants.buySatsMin || n > AppConstants.buySatsMax) return 'TZS ${AppConstants.buySatsMin} – ${AppConstants.buySatsMax}'; return null; }),
      const SizedBox(height: 16),
      InfoBanner(text: 'Send M-Pesa to agent ${AppConstants.mpesaAgent} for the exact amount.', color: AppColors.buySatsColor, icon: Icons.phone_android_rounded),
      const SizedBox(height: 28),
      GoldButton(label: 'Get Quote', onTap: _createQuote, loading: _loading, icon: Icons.search_rounded),

      const SizedBox(height: 28),
      Text('How Buy Bitcoin Works', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _HowItWorksStep(step: 1, text: 'Get a quote — server calculates sats at live price'),
      _HowItWorksStep(step: 2, text: 'Generate a BOLT11 invoice in your Lightning wallet'),
      _HowItWorksStep(step: 3, text: 'Send M-Pesa to agent ${AppConstants.mpesaAgent}'),
      _HowItWorksStep(step: 4, text: 'Submit quote ID + invoice + M-Pesa ID'),
      _HowItWorksStep(step: 5, text: 'Server verifies & pays your invoice instantly'),
    ])));
  }

  Widget _buildQuote() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      GlassCard(borderColor: AppColors.buySatsColor.withOpacity(0.3), child: Column(children: [
        Text('Your Quote', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Text('${_quote!.calculatedSats}', style: GoogleFonts.playfairDisplay(color: AppColors.buySatsColor, fontSize: 42, fontWeight: FontWeight.w700)),
        Text('sats', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14)),
        const Divider(height: 28, color: AppColors.border),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('You Pay (M-Pesa)', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text(CurrencyFormatter.tzs(_quote!.amountTZS), style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BTC Price', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text(CurrencyFormatter.usd(_quote!.btcPrice), style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13))]),
        if (_quote!.priceSource != null) ...[const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Source', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text(_quote!.priceSource!, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13))])],
      ])),
      const SizedBox(height: 16),
      InfoBanner(text: 'Create a BOLT11 invoice for exactly ${_quote!.calculatedSats} sats in your Lightning wallet. Quote valid for 30 minutes.', color: AppColors.warning, icon: Icons.warning_amber_rounded),
      const SizedBox(height: 16),
      InfoBanner(text: 'Send TZS ${_quote!.amountTZS} to M-Pesa agent ${AppConstants.mpesaAgent}', color: AppColors.buySatsColor, icon: Icons.phone_android_rounded),
      const SizedBox(height: 28),
      GoldButton(label: 'I\'ve Paid & Have Invoice', onTap: () => setState(() => _step = BuyStep.verify), icon: Icons.arrow_forward_rounded),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: _reset, child: const Text('Start Over')),
    ]));
  }

  Widget _buildVerify() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Paste Your BOLT11 Invoice', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(controller: _bolt11Ctrl, maxLines: 3, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 12),
          decoration: InputDecoration(hintText: 'lnbc...', hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12))),
      const SizedBox(height: 18),
      Text('M-Pesa Transaction ID', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(controller: _mpesaIdCtrl, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: 'e.g. DAM2MFP8VYM', hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted))),
      const SizedBox(height: 16),
      GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Quote Sats', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text('${_quote!.calculatedSats} sats', style: GoogleFonts.dmSans(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('M-Pesa Amount', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text(CurrencyFormatter.tzs(_quote!.amountTZS), style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))]),
      ])),
      const SizedBox(height: 16),
      const InfoBanner(text: 'Server verifies M-Pesa amount, invoice amount, and prevents replay. All checks are server-side.', color: AppColors.info),
      const SizedBox(height: 28),
      GoldButton(label: 'Claim Sats', onTap: _sendSats, loading: _loading, icon: Icons.bolt_rounded),
    ]));
  }

  Widget _buildSuccess() {
    return Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.buySatsColor.withOpacity(0.12), border: Border.all(color: AppColors.buySatsColor.withOpacity(0.3), width: 2)),
          child: const Icon(Icons.bolt_rounded, color: AppColors.buySatsColor, size: 40)),
      const SizedBox(height: 24),
      Text('Sats Sent!', style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('${_quote!.calculatedSats} sats have been sent to your Lightning wallet.', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      GoldButton(label: 'Buy More', onTap: _reset, icon: Icons.currency_bitcoin_rounded),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
    ]));
  }
}

class _HowItWorksStep extends StatelessWidget {
  final int step;
  final String text;
  const _HowItWorksStep({required this.step, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.buySatsColor.withOpacity(0.12)),
          child: Center(child: Text('$step', style: GoogleFonts.dmSans(color: AppColors.buySatsColor, fontSize: 11, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12))),
    ]));
  }
}