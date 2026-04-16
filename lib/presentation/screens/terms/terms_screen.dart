import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: const [
        Text('ChapSmart Terms of Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.t1)),
        SizedBox(height: 4),
        Text('Last updated: April 2026', style: TextStyle(fontSize: 12, color: C.t3)),
        SizedBox(height: 20),
        _S('1. About ChapSmart', 'ChapSmart is a financial technology platform registered in Moshi, Kilimanjaro, Tanzania. We provide Bitcoin-to-Mobile Money exchange services including remittance (Bitcoin → M-Pesa), airtime top-up (Bitcoin → Airtime), and Buy Sats (M-Pesa → Bitcoin via Lightning Network).'),
        _S('2. Eligibility', 'You must be at least 18 years old and located in Tanzania to use Buy Sats services. Remittance and airtime services are available globally.'),
        _S('3. Account & Security', 'Your ChapSmart account is identified by a unique account number. You are responsible for keeping it secure. ChapSmart does not collect personal identifying information (no KYC). Device fingerprinting and phone binding are used for fraud prevention.'),
        _S('4. Services', 'Send (Remittance): Bitcoin/Lightning to M-Pesa TZS (TZS 2,500 – 1,000,000).\n\nAirtime: Bitcoin/Lightning to mobile airtime (TZS 500 – 15,000).\n\nBuy Sats: M-Pesa TZS to Bitcoin via Lightning (TZS 1,000 – 100,000). Daily limit: 10 transactions.'),
        _S('5. Fees', 'Fees based on loyalty tier:\n• Bronze: 2.20%\n• Silver: 1.87% (after TZS 5M cumulative)\n• Gold: 1.32% (after TZS 25M cumulative)\n\nExchange rates sourced from Binance and OKX in real-time.'),
        _S('6. Transactions', 'All transactions are final once confirmed. Quotes valid for 30 minutes. ChapSmart is not responsible for incorrect phone numbers or wallet addresses.'),
        _S('7. Prohibited Use', 'You may not use ChapSmart for money laundering, terrorism financing, fraud, or any activity violating Tanzanian law.'),
        _S('8. Privacy', 'ChapSmart collects minimal data: account number, device fingerprint, phone number (Buy Sats), and transaction history. We do not share data with third parties except as required by law.'),
        _S('9. Account Deletion', 'You may delete your account at any time from Profile. Deletion is permanent and irreversible.'),
        _S('10. Limitation of Liability', 'ChapSmart provides services "as is" without warranties. Not liable for Bitcoin price fluctuations, network delays, or M-Pesa downtime.'),
        _S('11. Governing Law', 'Governed by laws of the United Republic of Tanzania. Disputes resolved through arbitration in Moshi, Kilimanjaro.'),
        _S('12. Contact', 'Email: support@chapsmart.com\nWebsite: https://chapsmart.com'),
        SizedBox(height: 40),
      ])),
    );
  }
}

class _S extends StatelessWidget {
  final String title, body;
  const _S(this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.t1)),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(fontSize: 13, color: C.t2, height: 1.7)),
    ]));
  }
}
