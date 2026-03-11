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

enum RemittanceStep { form, quote, invoice, success }

class RemittanceScreen extends StatefulWidget {
  const RemittanceScreen({super.key});
  @override
  State<RemittanceScreen> createState() => _RemittanceScreenState();
}

class _RemittanceScreenState extends State<RemittanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  RemittanceStep _step = RemittanceStep.form;
  bool _loading = false;
  Quote? _quote;
  Invoice? _invoice;
  Timer? _pollTimer;
  int _pollCountdown = AppConstants.quotePollSeconds;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final acc = await _storage.read(key: AppConstants.keyAccountNumber) ?? '';
      final res = await _api.createQuote(
        amountTZS: int.parse(_amountCtrl.text.replaceAll(',', '')),
        phoneNumber: _phoneCtrl.text.trim(),
        recipientName: _nameCtrl.text.trim(),
        accountNumber: acc,
      );
      setState(() {
        _quote = Quote.fromJson(res);
        _step = RemittanceStep.quote;
      });
      _startPollTimer();
    } catch (e) {
      _showError('Failed to get quote');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPollTimer() {
    _pollCountdown = AppConstants.quotePollSeconds;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      setState(() => _pollCountdown--);
      if (_pollCountdown <= 0) {
        _pollCountdown = AppConstants.quotePollSeconds;
        try {
          final res = await _api.pollQuote(_quote!.quoteId);
          if (mounted) setState(() => _quote = Quote.fromJson(res));
        } catch (_) {}
      }
    });
  }

  Future<void> _generateInvoice() async {
    setState(() => _loading = true);
    _pollTimer?.cancel();
    try {
      final res = await _api.generateInvoice(_quote!.quoteId);
      setState(() { _invoice = Invoice.fromJson(res); _step = RemittanceStep.invoice; });
    } catch (e) {
      _showError('Failed to generate invoice');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _pollTimer?.cancel();
    setState(() { _step = RemittanceStep.form; _quote = null; _invoice = null; _amountCtrl.clear(); _phoneCtrl.clear(); _nameCtrl.clear(); });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step != RemittanceStep.form) {
              _pollTimer?.cancel();
              setState(() => _step = RemittanceStep.form);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_step) {
            RemittanceStep.form => _buildForm(),
            RemittanceStep.quote => _buildQuote(),
            RemittanceStep.invoice => _buildInvoice(),
            RemittanceStep.success => _buildSuccess(),
          },
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
    RemittanceStep.form => 'BitRemit',
    RemittanceStep.quote => 'Review Quote',
    RemittanceStep.invoice => 'Pay Invoice',
    RemittanceStep.success => 'Payment Sent',
  };

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.remittanceColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.remittanceColor.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.remittanceColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.send_rounded, color: AppColors.remittanceColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BTC → M-Pesa', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Send Bitcoin, recipient receives TZS', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        _label('Amount (TZS)'),
        TextFormField(
          controller: _amountCtrl, keyboardType: TextInputType.number,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(prefixText: 'TZS ', hintText: '0'),
          validator: (v) { final n = int.tryParse(v?.replaceAll(',', '') ?? ''); if (n == null || n < AppConstants.remitMin || n > AppConstants.remitMax) return 'TZS ${AppConstants.remitMin} – ${AppConstants.remitMax}'; return null; },
        ),
        const SizedBox(height: 18),
        _label('Recipient Phone'),
        TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(prefixText: '+', hintText: '255740034110'),
            validator: (v) { if (v == null || v.trim().length < 9) return 'Enter a valid phone number'; return null; }),
        const SizedBox(height: 18),
        _label('Recipient Name'),
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. John Mwita'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        const InfoBanner(text: 'Live price updates every 60s. Lock rate when ready.', color: AppColors.warning, icon: Icons.schedule_rounded),
        const SizedBox(height: 28),
        GoldButton(label: 'Get Quote', onTap: _createQuote, loading: _loading, icon: Icons.search_rounded),
      ])),
    );
  }

  Widget _buildQuote() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withOpacity(0.25))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 15), const SizedBox(width: 6), Text('Price refreshes in', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 12))]),
            Text('${_pollCountdown}s', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('You Pay', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
              TierBadge(tier: _quote!.userTier),
            ]),
            const SizedBox(height: 8),
            Text(CurrencyFormatter.sats(_quote!.sats), style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontSize: 34, fontWeight: FontWeight.w700)),
            Text(CurrencyFormatter.btc(_quote!.btc), style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
            const Divider(height: 28, color: AppColors.border),
            _InfoRow('Recipient Gets', CurrencyFormatter.tzs(_quote!.amountTZS), highlight: true),
            const SizedBox(height: 10),
            _InfoRow('Network Fee', '${CurrencyFormatter.sats(_quote!.feeSats)} (${CurrencyFormatter.percent(_quote!.feePercent)})'),
          ]),
        ),
        const SizedBox(height: 28),
        GoldButton(label: 'Lock Price & Generate Invoice', onTap: _generateInvoice, loading: _loading, icon: Icons.lock_rounded),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _reset, child: const Text('Start Over')),
      ]),
    );
  }

  Widget _buildInvoice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        GlassCard(
          child: Column(children: [
            Text('Scan to Pay', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: QrImageView(data: _invoice!.bolt11, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 16),
            Text(CurrencyFormatter.sats(_invoice!.sats), style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('= ${CurrencyFormatter.tzs(_invoice!.amountTZS)}', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        CopyField(label: 'Lightning Invoice (BOLT11)', value: _invoice!.bolt11),
        const SizedBox(height: 8),
        CopyField(label: 'Invoice ID', value: _invoice!.invoiceId),
        const SizedBox(height: 24),
        GoldButton(label: "I've Sent Payment", onTap: () => setState(() => _step = RemittanceStep.success), icon: Icons.check_circle_rounded),
        const SizedBox(height: 12),
        Text('Payment confirmed automatically via webhook', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withOpacity(0.12), border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2)),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40)),
        const SizedBox(height: 24),
        Text('Payment Submitted!', style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Your payment is being processed. The recipient will receive ${CurrencyFormatter.tzs(_invoice!.amountTZS)} via M-Pesa.',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        GoldButton(label: 'Send Another', onTap: _reset, icon: Icons.send_rounded),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
      ]),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3)));
}

class _InfoRow extends StatelessWidget {
  final String l, v;
  final bool highlight;
  const _InfoRow(this.l, this.v, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
    Text(v, style: GoogleFonts.dmSans(color: highlight ? AppColors.success : AppColors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
  ]);
}