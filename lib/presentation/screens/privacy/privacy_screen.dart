import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 4),
          Text('Effective Date: 15 April 2026 \u00b7 Last Updated: 15 April 2026', style: TextStyle(fontSize: 12, color: C.t3, fontFamily: 'SpaceMono')),
          const SizedBox(height: 24),

          _Section('1. Introduction',
            'This Privacy Policy describes how Chapsmart Payments ("Chapsmart", "we", "us" or "our"), '
            'registered with BRELA under Registration Number 638852, collects, uses, stores, and protects '
            'your information when you use our mobile application and services.\n\n'
            'Chapsmart is committed to protecting your privacy. We collect only the minimum personal information '
            'necessary to provide our Services and comply with legal obligations. We process personal data in '
            'accordance with the Personal Data Protection Act, 2022, and its implementing regulations.'),

          _Section('2. Information We Collect',
            'Chapsmart collects the following categories of data:\n\n'
            '\u2022 Account Number \u2014 A unique 16-digit identifier generated upon registration. This is your '
            'primary login credential. No name, email, or government ID is required.\n\n'
            '\u2022 Device Identifier \u2014 A device fingerprint used solely for fraud prevention and anti-scam '
            'measures (e.g., detecting multiple accounts per device).\n\n'
            '\u2022 Phone Number \u2014 Collected only when you use Buy Sats or Remittance services. Used to deliver '
            'M-Pesa payments or airtime to the correct recipient. Phone numbers are bound to accounts for security.\n\n'
            '\u2022 Transaction Data \u2014 Records of your transactions including amounts, timestamps, service type '
            '(Remittance, Airtime, Buy Sats), and transaction status. Used for service delivery, dispute resolution, '
            'and legal compliance.\n\n'
            '\u2022 IP Address \u2014 Logged for geo-restriction enforcement (Buy Sats is available only in Tanzania) '
            'and security monitoring.\n\n'
            '\u2022 Push Notification Token \u2014 If you enable push notifications, your device token is stored to '
            'deliver transaction updates.'),

          _Section('3. Information We Do NOT Collect',
            'Chapsmart does not collect:\n\n'
            '\u2022 Your name, email address, or physical address\n'
            '\u2022 Government-issued identification documents (no KYC)\n'
            '\u2022 GPS location or precise geolocation\n'
            '\u2022 Contacts, photos, or files from your device\n'
            '\u2022 Browsing history or app usage analytics\n'
            '\u2022 Biometric data (fingerprint, face ID)\n\n'
            'We do not use any third-party analytics, advertising, or tracking SDKs.'),

          _Section('4. How We Use Your Information',
            'We use the collected information exclusively for:\n\n'
            '\u2022 Providing the Services \u2014 Processing remittances, airtime purchases, and Bitcoin transactions.\n'
            '\u2022 Fraud Prevention \u2014 Device fingerprinting and phone binding to prevent abuse and protect users.\n'
            '\u2022 Legal Compliance \u2014 Meeting obligations under the Anti-Money Laundering Act, 2006, the Finance '
            'Act, 2024, and cooperation with the Financial Intelligence Unit (FIU) when required by law.\n'
            '\u2022 Customer Support \u2014 Resolving transaction disputes and responding to support inquiries.\n'
            '\u2022 Service Improvement \u2014 Monitoring system performance and reliability.'),

          _Section('5. Data Storage and Security',
            'Your data is stored on secure servers with the following protections:\n\n'
            '\u2022 TLS encryption for all data in transit\n'
            '\u2022 Firebase Firestore with security rules for data at rest\n'
            '\u2022 Firebase App Check to prevent unauthorized API access\n'
            '\u2022 Rate limiting and reverse-proxy hardening (Caddy)\n'
            '\u2022 Encrypted local storage on your device (flutter_secure_storage)\n\n'
            'Account credentials (account number, authentication tokens) are stored in your device\'s encrypted '
            'keychain/keystore and are never transmitted in plain text.'),

          _Section('6. Data Sharing',
            'Chapsmart does not sell, rent, or trade your personal data to third parties.\n\n'
            'We may share limited data with:\n\n'
            '\u2022 Licensed Payment Partners \u2014 Phone numbers and transaction amounts are shared with our '
            'licensed M-Pesa and airtime partners (Selcom, Beem Africa) solely to process your transactions.\n'
            '\u2022 Firebase/Google \u2014 Firebase services (Authentication, Firestore, App Check) process data '
            'under Google\'s data processing terms.\n'
            '\u2022 Law Enforcement \u2014 When required by law or by a duly authorized Tanzanian authority '
            '(FIU, TRA, BoT), we may disclose transaction records as required by the Anti-Money Laundering Act.'),

          _Section('7. Data Retention',
            'We retain your data as follows:\n\n'
            '\u2022 Account data \u2014 Retained for as long as your account is active.\n'
            '\u2022 Transaction records \u2014 Retained for the period required by applicable Tanzanian law '
            '(currently a minimum of 5 years under AML regulations).\n'
            '\u2022 Device identifiers \u2014 Retained for as long as your account is active.\n\n'
            'Upon account deletion, your account number, bound phone numbers, and transaction history are '
            'permanently removed from our active systems. Archived records required by law may be retained '
            'separately for the legally mandated period.'),

          _Section('8. Account Deletion',
            'You may delete your account at any time from the Profile screen in the app. Account deletion is '
            'permanent and irreversible. Upon deletion:\n\n'
            '\u2022 Your account number is deactivated\n'
            '\u2022 All bound phone numbers are unlinked\n'
            '\u2022 Transaction history is removed from active systems\n'
            '\u2022 Local credentials are cleared from your device\n\n'
            'Pending transactions must complete before deletion can proceed.'),

          _Section('9. Children\'s Privacy',
            'Chapsmart Services are not directed to individuals under the age of 18. We do not knowingly collect '
            'personal information from children. If we become aware that we have collected data from a person under '
            '18, we will promptly delete such information.'),

          _Section('10. Your Rights',
            'Under the Personal Data Protection Act, 2022, you have the right to:\n\n'
            '\u2022 Access your personal data held by Chapsmart\n'
            '\u2022 Request correction of inaccurate data\n'
            '\u2022 Request deletion of your data (subject to legal retention requirements)\n'
            '\u2022 Object to processing of your data\n\n'
            'To exercise any of these rights, contact us at support@chapsmart.com with your Account Number.'),

          _Section('11. Changes to This Policy',
            'Chapsmart may update this Privacy Policy from time to time. Changes become effective upon publication '
            'in the app. For material changes, we will make reasonable efforts to notify users through the app '
            'or other available channels. We encourage you to review this policy periodically.'),

          _Section('12. Contact',
            'For privacy-related inquiries:\n\n'
            'Email: support@chapsmart.com\n'
            'Website: www.chapsmart.com\n'
            'Location: Kilimanjaro, Moshi, United Republic of Tanzania'),

          const SizedBox(height: 16),
          Text(
            'By using Chapsmart Services, you acknowledge that you have read and understood this Privacy Policy.',
            style: TextStyle(fontSize: 13, color: C.t3, fontStyle: FontStyle.italic, height: 1.6),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, body;
  const _Section(this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.btc, width: 2))),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.t1)),
        ),
        const SizedBox(height: 10),
        Text(body, style: TextStyle(fontSize: 13.5, color: C.t2, height: 1.7)),
      ]),
    );
  }
}
