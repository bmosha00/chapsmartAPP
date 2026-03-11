import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

enum AirtimeStep { form, quote, invoice, success }

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});
  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  AirtimeStep _step = AirtimeStep.form;
  bool _loading = false;
  Quote? _quote;
  Invoice? _invoice;
  Timer? _pollTimer;
  int _pollCountdown = AppConstants.quotePollSeconds;

  // Quick amounts for airtime
  final _quickAmounts = [500, 1000, 2000, 5000, 10000, 15000];

  @override
  void dispose() { _pollTimer?.cancel(); _amountCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final acc = await _storage.read(key: AppConstants.keyAccountNumber) ?? '';
      final res = await _api.createAirtimeQuote(amountTZS: int.parse(_amountCtrl.text.replaceAll(',', '')), phoneNumber: _phoneCtrl.text.trim(), accountNumber: acc);
      setState(() { _quote = Quote.fromJson(res); _step = AirtimeStep.quote; });
      _startPollTimer();
    } catch (e) { _showError('Failed to get quote'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _startPollTimer() {
    _pollCountdown = AppConstants.quotePollSeconds;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      setState(() => _pollCountdown--);
      if (_pollCountdown <= 0) {
        _pollCountdown = AppConstants.quotePollSeconds;
        try { final res = await _api.pollAirtimeQuote(_quote!.quoteId); if (mounted) setState(() => _quote = Quote.fromJson(res)); } catch (_) {}
      }
    });
  }

  Future<void> _generateInvoice() async {
    setState(() => _loading = true);
    _pollTimer?.cancel();
    try {
      final res = await _api.generateAirtimeInvoice(_quote!.quoteId);
      setState(() { _invoice = Invoice.fromJson(res); _step = AirtimeStep.invoice; });
    } catch (e) { _showError('Failed to generate invoice'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _reset() { _pollTimer?.cancel(); setState(() { _step = AirtimeStep.form; _quote = null; _invoice = null; _amountCtrl.clear(); _phoneCtrl.clear(); }); }
  void _showError(String msg) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == AirtimeStep.form ? 'PayBill - Airtime' : _step == AirtimeStep.quote ? 'Review Quote' : _step == AirtimeStep.invoice ? 'Pay Invoice' : 'Success'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (_step != AirtimeStep.form) { _pollTimer?.cancel(); setState(() => _step = AirtimeStep.form); } else { Navigator.of(context).pop(); } })),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildBody())),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case AirtimeStep.form: return _buildForm();
      case AirtimeStep.quote: return _buildQuote();
      case AirtimeStep.invoice: return _buildInvoice();
      case AirtimeStep.success: return _buildSuccess();
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.airtimeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.airtimeColor.withOpacity(0.2))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.airtimeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.phone_android_rounded, color: AppColors.airtimeColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BTC → Airtime', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Send Bitcoin, recipient receives airtime', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          ])),
      const SizedBox(height: 24),
      Text('Quick Amount', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _quickAmounts.map((a) => GestureDetector(
          onTap: () => setState(() => _amountCtrl.text = a.toString()),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(
              color: _amountCtrl.text == a.toString() ? AppColors.airtimeColor.withOpacity(0.15) : AppColors.surface,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: _amountCtrl.text == a.toString() ? AppColors.airtimeColor : AppColors.border)),
              child: Text('TZS ${a.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: GoogleFonts.dmSans(color: _amountCtrl.text == a.toString() ? AppColors.airtimeColor : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)))
      )).toList()),
      const SizedBox(height: 18),
      Text('Amount (TZS)', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(prefixText: 'TZS ', hintText: '0'),
          validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); if (n == null || n < AppConstants.airtimeMin || n > AppConstants.airtimeMax) return 'TZS ${AppConstants.airtimeMin} – ${AppConstants.airtimeMax}'; return null; }),
      const SizedBox(height: 18),
      Text('Phone Number', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(prefixText: '+', hintText: '255740034110'),
          validator: (v) { if (v == null || v.trim().length < 9) return 'Enter a valid phone number'; return null; }),
      const SizedBox(height: 16),
      const InfoBanner(text: 'Airtime will be sent to the number above via Beem Africa.', color: AppColors.airtimeColor, icon: Icons.info_outline_rounded),
      const SizedBox(height: 28),
      GoldButton(label: 'Get Quote', onTap: _createQuote, loading: _loading, icon: Icons.search_rounded),
    ])));
  }

  Widget _buildQuote() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withOpacity(0.25))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 15), const SizedBox(width: 6), Text('Refreshes in', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 12))]),
            Text('${_pollCountdown}s', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.w700)),
          ])),
      const SizedBox(height: 24),
      GlassCard(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('You Pay', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), TierBadge(tier: _quote!.userTier)]),
        const SizedBox(height: 8),
        Text(CurrencyFormatter.sats(_quote!.sats), style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontSize: 34, fontWeight: FontWeight.w700)),
        const Divider(height: 28, color: AppColors.border),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Airtime Amount', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)), Text(CurrencyFormatter.tzs(_quote!.amountTZS), style: GoogleFonts.dmSans(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600))]),
      ])),
      const SizedBox(height: 28),
      GoldButton(label: 'Lock Price & Generate Invoice', onTap: _generateInvoice, loading: _loading, icon: Icons.lock_rounded),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: _reset, child: const Text('Start Over')),
    ]));
  }

  Widget _buildInvoice() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(children: [
      GlassCard(child: Column(children: [
        Text('Scan to Pay', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: QrImageView(data: _invoice!.bolt11, version: QrVersions.auto, size: 200)),
        const SizedBox(height: 16),
        Text(CurrencyFormatter.sats(_invoice!.sats), style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w700)),
      ])),
      const SizedBox(height: 16),
      CopyField(label: 'BOLT11 Invoice', value: _invoice!.bolt11),
      const SizedBox(height: 24),
      GoldButton(label: "I've Sent Payment", onTap: () => setState(() => _step = AirtimeStep.success), icon: Icons.check_circle_rounded),
    ]));
  }

  Widget _buildSuccess() {
    return Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withOpacity(0.12), border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2)),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40)),
      const SizedBox(height: 24),
      Text('Airtime Sent!', style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Airtime of ${CurrencyFormatter.tzs(_invoice!.amountTZS)} is being delivered.', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      GoldButton(label: 'Top Up Again', onTap: _reset, icon: Icons.phone_android_rounded),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
    ]));
  }
}