import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Text('Terms and Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.t1)),
          const SizedBox(height: 4),
          Text('Effective Date: 15 April 2026 · Last Updated: 15 April 2026', style: TextStyle(fontSize: 12, color: C.t3, fontFamily: 'SpaceMono')),
          const SizedBox(height: 24),

          // 1. About Chapsmart
          _Section('1. About Chapsmart',
            'These Terms and Conditions ("Terms") form a binding agreement between Chapsmart Payments '
            '(hereinafter "Chapsmart", "we", "us" or "our") and any person who registers for or uses our Services ("User" or "you").\n\n'
            'Chapsmart is a business duly registered with the Business Registrations and Licensing Agency (BRELA) under '
            'Registration Number 638852, and operates exclusively within the United Republic of Tanzania. We operate a '
            'regulated-ecosystem bridge that converts Bitcoin (received via the Bitcoin Lightning Network) into Tanzanian '
            'Shillings (TZS) and delivers the proceeds to recipients in Tanzania through licensed mobile money channels, '
            'and vice versa. All of our domestic transactions are settled exclusively in Tanzanian Shillings (TZS), which '
            'is the sole legal tender of the United Republic of Tanzania under Section 26 of the Bank of Tanzania Act, 2006 '
            '(as amended by the Finance Act, 2024).'),

          _InfoBox('Legal Registration: Chapsmart is registered with BRELA under Registration Number 638852, '
            'issued under the Business Names (Registration) Act (Cap. 213). This registration is publicly verifiable '
            'through BRELA\'s Online Registration System at ors.brela.go.tz.'),

          _Detail('Location: Kilimanjaro, Moshi, United Republic of Tanzania.\n'
            'Contact: support@chapsmart.com · www.chapsmart.com'),

          // 2. Scope of Services
          _Section('2. Scope of Services',
            'Chapsmart provides three core services within the territory of the United Republic of Tanzania. '
            'All disbursements to recipients in Tanzania are made exclusively in Tanzanian Shillings (TZS) '
            'through licensed mobile money channels.'),

          _ServiceTable(),

          _Detail('Transaction amount limits apply to each Service and are displayed in the Platform at the time of '
            'transaction. Chapsmart may adjust these limits from time to time at its discretion.\n\n'
            'Chapsmart acts as a bridge between the Bitcoin Lightning Network and Tanzania\'s licensed financial infrastructure. '
            'We do not hold, store, or take custody of user funds beyond the short time strictly necessary to complete each '
            'transaction. We are not a wallet, savings service, deposit-taking institution, or lender.'),

          // 3. Authorized Business Activities
          _Section('3. Authorized Business Activities',
            'Chapsmart is authorized to operate under the following ISIC codes, as recorded in our BRELA Extract '
            'from Register (Form 21, Registration No. 638852):\n\n'
            '• ISIC 6499 — Other financial service activities (Main activity)\n'
            '• ISIC 6619 — Other activities auxiliary to financial service activities (Main activity)\n'
            '• ISIC 6209 — Other information technology and computer service activities\n'
            '• ISIC 6399 — Other information service activities n.e.c.\n\n'
            'Chapsmart also holds a valid municipal business license authorizing "Huduma ya Miamala ya Simu na '
            'Huduma Ndogo za Kibenki" (Mobile Transaction Services and Small Banking Services), renewed annually '
            'in accordance with the Business Licensing Act, 1972 (Act No. 25).'),

          // 4. Legal Framework
          _Section('4. Legal Framework Governing Chapsmart\'s Operations', ''),

          _SubSection('4.1 Tanzanian Shilling as Sole Legal Tender',
            'The Tanzanian Shilling (TZS) is the sole legal tender of the United Republic of Tanzania, established under:\n\n'
            '• Sections 26 and 27 of the Bank of Tanzania Act, 2006 — exclusive authority to issue banknotes and coins.\n'
            '• Section 26(2) as amended by the Finance Act, 2024 — transacting domestically in any currency other than TZS is an offence.\n'
            '• The Foreign Exchange Regulations, 2025 (GN No. 198 of 2025, effective 28 March 2025) — all domestic transactions must be settled in TZS.\n\n'
            'How Chapsmart complies: Every domestic disbursement made by Chapsmart to a Tanzanian recipient is in TZS. '
            'We do not price, invoice, disburse, or settle any domestic transaction in Bitcoin, US Dollars, or any other non-TZS currency.'),

          _SubSection('4.2 Bank of Tanzania Public Notice on Cryptocurrency (12 November 2019)',
            'On 12 November 2019, the Bank of Tanzania (BoT) issued a Public Notice cautioning members of the public '
            'against trading, marketing, or using virtual currencies.\n\n'
            'How Chapsmart addresses this notice: Chapsmart does not treat Bitcoin as legal tender in Tanzania, does not '
            'market Bitcoin as a means of payment for domestic transactions, and does not disburse Bitcoin to recipients '
            'inside Tanzania as payment for goods or services. Our model reinforces TZS as the sole domestic medium of exchange.'),

          _SubSection('4.3 Finance Act, 2024 — Statutory Recognition of Digital Assets',
            'The Finance Act, 2024 (effective 1 July 2024) introduced the first formal statutory recognition of digital '
            'assets in Tanzanian law:\n\n'
            '• Section 83C of the Income Tax Act (Cap. 332): Imposes a 3% withholding tax on payments made by persons '
            'who own a digital asset exchange platform, or who facilitate the exchange or transfer of a digital asset.\n\n'
            '• Statutory definition of "digital asset": Anything of value that is not tangible, including cryptocurrencies, '
            'token codes, and numbers held in digital form and generated through cryptographic means.\n\n'
            'How Chapsmart complies: We apply the 3% withholding tax to every qualifying digital asset transaction, '
            'collect it at the point of transaction, and remit it to the TRA as required by law.'),

          _SubSection('4.4 Yellow Card Tanzania Ltd v. Nyamwero (2024) — Judicial Precedent',
            'In this landmark decision (Commercial Case No. 12171 of 2024, High Court of Tanzania, decided 13 December 2024), '
            'the Court established three key principles:\n\n'
            '1. The validity of a contract is independent of whether its subject matter is regulated.\n'
            '2. Cryptocurrency transactions are not inherently illegal in Tanzania when operators comply with tax and financial laws.\n'
            '3. Virtual currency transactions become unlawful only if linked to money laundering, terrorism financing, or other illicit activities.\n\n'
            'Chapsmart\'s operations are fully aligned with these principles.'),

          _SubSection('4.5 Executive Policy Direction',
            'In June 2021, President Samia Suluhu Hassan publicly urged the Bank of Tanzania to "be prepared" for '
            'the advent of cryptocurrencies and blockchain technology, informing subsequent policy developments including '
            'the Finance Act, 2024.'),

          // 5. Operating Model
          _Section('5. Operating Model — Working with Licensed Payment Partners',
            'Chapsmart processes all M-Pesa disbursements and Tanzanian payment flows through licensed third-party '
            'payment partners that hold authorizations from the Bank of Tanzania under the National Payment Systems Act, 2015. '
            'These partners include licensed Payment System Providers (PSPs), Mobile Network Operators (MNOs), and telecom '
            'service platforms.\n\n'
            'Every transaction processed by Chapsmart flows through a fully regulated segment of Tanzania\'s national payment system.'),

          // 6. Definitions
          _Section('6. Definitions',
            '• Account Number: The unique 16-digit number assigned to your User Account.\n'
            '• Bridge: Chapsmart\'s function as an intermediary between Bitcoin and TZS.\n'
            '• Business Day: An official working day in Tanzania (Monday to Friday, excluding public holidays).\n'
            '• Digital Asset: As defined under the Finance Act, 2024.\n'
            '• Lightning Network: A second-layer payment protocol on Bitcoin for fast, low-cost transactions.\n'
            '• M-Pesa: The licensed mobile money service operated in Tanzania by Vodacom Tanzania.\n'
            '• Services: Remittance, Airtime, and Buy Sats.\n'
            '• TZS: The sole legal tender of Tanzania.\n'
            '• User Account: An account identified by your unique 16-digit Account Number.\n'
            '• Platform: The Chapsmart website, mobile application, or other digital interfaces.'),

          // 7. User Account
          _Section('7. User Account',
            'To use the Services, you must create a User Account. Upon registration, you will be assigned a unique '
            '16-digit Account Number, which serves both as your identifier and login credential. No government-issued '
            'identification documents are required for basic registration, although Chapsmart may request additional '
            'verification for compliance purposes.\n\n'
            'You must treat your Account Number as confidential and must not disclose it to any third party. Any activity '
            'through your User Account is deemed to be conducted by you.\n\n'
            'If you suspect your Account Number has been compromised, contact us immediately at support@chapsmart.com.'),

          // 8. Eligibility
          _Section('8. Eligibility',
            'By registering for a Chapsmart User Account, you represent and warrant that:\n\n'
            '• You have full legal capacity to enter into these Terms.\n'
            '• You are at least 18 years of age.\n'
            '• You have not been previously suspended or removed from Chapsmart.\n'
            '• You do not currently hold another Chapsmart User Account.\n'
            '• You are not using Chapsmart to facilitate any prohibited activity.\n'
            '• You are not a person sanctioned by the UN, EU, OFAC, or any recognized sanctions authority.\n'
            '• You are solely responsible for ensuring compliance with applicable laws.'),

          // 9. Nature of Service
          _Section('9. Nature of Service: Bridge, Not Custodian',
            'Chapsmart operates strictly as a bridge between Bitcoin (via the Lightning Network) and Tanzania\'s '
            'licensed financial ecosystem.\n\n'
            '• Remittance: You send Bitcoin via Lightning Network → Chapsmart converts to TZS → disbursed to M-Pesa.\n'
            '• Airtime: You send Bitcoin → Chapsmart delivers airtime credit to the designated phone number.\n'
            '• Buy Sats: You send TZS via M-Pesa → Chapsmart sends Bitcoin to your external Lightning wallet.'),

          _InfoBox('No Custody of User Funds: Chapsmart does not hold, store, or take custody of your Bitcoin or TZS '
            'beyond the time strictly necessary to complete the conversion and disbursement. We are not a wallet, savings '
            'service, lending institution, or deposit-taking entity.'),

          // 10. Exchange Rate
          _Section('10. Exchange Rate and Transaction Confirmation',
            'Chapsmart quotes an exchange rate at the time you initiate each transaction, derived from prevailing market rates '
            'and adjusted for our service fee and the 3% withholding tax (where applicable). Once you confirm a transaction, '
            'the rate and fees shown at confirmation apply regardless of subsequent market movements.'),

          // 11. Fees and Taxes
          _Section('11. Fees and Taxes',
            'Chapsmart charges a service fee based on your loyalty tier. A 3% statutory withholding tax is applied to '
            'all qualifying transactions under Section 83C of the Income Tax Act (Cap. 332).'),

          _FeeTable(),

          _Detail('The 3% government tax is applied uniformly to all tiers. Buy Sats transactions do not receive tier discounts.\n\n'
            'Tax remittance: Chapsmart remits the 3% withholding tax to the TRA as required by law.\n\n'
            'User\'s tax obligations: Users outside Tanzania are solely responsible for their own tax obligations. '
            'The 3% withholding tax does not satisfy any tax obligation in another jurisdiction.'),

          // 12. AML/CFT
          _Section('12. Anti-Money Laundering, Counter-Terrorism Financing & Compliance',
            'In line with the Anti-Money Laundering Act, 2006 (Cap. 423 R.E. 2022), Chapsmart maintains procedures for:\n\n'
            '• Monitoring transactions and identifying suspicious activity\n'
            '• Applying risk-based enhanced due diligence\n'
            '• Cooperating with the FIU, TRA, BoT, and other authorities\n'
            '• Reporting suspicious transactions\n'
            '• Suspending or rejecting transactions connected to unlawful activity\n'
            '• Requesting additional user information where required for compliance\n'
            '• Retaining transaction records per applicable laws\n\n'
            'Users agree not to use Chapsmart for money laundering, terrorism financing, sanctions evasion, fraud, '
            'tax evasion, human trafficking, drug trafficking, or any prohibited activity.'),

          // 13. Data Protection
          _Section('13. Data Protection and Privacy',
            'Chapsmart collects only the minimum personal information necessary to provide the Services and comply with '
            'legal obligations. We process personal data in accordance with the Personal Data Protection Act, 2022.\n\n'
            'Where required by law or by a duly authorized Tanzanian authority, Chapsmart may share user transaction data. '
            'Otherwise, we do not sell or share user data with third parties.'),

          // 14. Risks
          _Section('14. Risks Associated with Digital Assets',
            '• Bitcoin is not legal tender in Tanzania — Chapsmart only disburses TZS within Tanzania.\n'
            '• Evolving regulation — future regulatory changes may affect the Services.\n'
            '• Price volatility — Bitcoin prices can be highly volatile; you bear the risk of price movements.\n'
            '• User-side security risks — compromised devices, lost wallet keys, SIM-swap attacks.\n'
            '• Third-party infrastructure risks — delays or outages on external networks.\n'
            '• Lightning Network risks — transactions may fail, time out, or experience routing difficulties.\n'
            '• No custody exposure — once TZS is delivered, risk is borne by the holder.\n'
            '• Irreversibility — Bitcoin transactions are irreversible once confirmed.\n\n'
            'By creating a User Account, you acknowledge these risks and confirm your financial standing is suitable '
            'for your use of the Services.'),

          // 15. Prohibited Activities
          _Section('15. Prohibited Activities',
            'You may not use Chapsmart\'s Services to:\n\n'
            '• Engage in or facilitate money laundering, terrorism financing, or sanctions evasion\n'
            '• Purchase or trade illegal goods or services\n'
            '• Conduct fraud, identity theft, or phishing\n'
            '• Evade taxes or conceal taxable income\n'
            '• Circumvent any legal or regulatory requirement\n'
            '• Operate as an unlicensed money transmitter or exchange\n'
            '• Attempt to breach or reverse-engineer Chapsmart\'s security\n'
            '• Use automated means (bots, scripts, scrapers) without consent\n'
            '• Provide false, misleading, or impersonated information\n\n'
            'Breach of this section may result in immediate suspension or termination, forfeiture of pending '
            'transactions, and reporting to authorities.'),

          // 16. Liability
          _Section('16. Liability',
            'Users are responsible for protecting their Account Number and access credentials. Chapsmart shall not be '
            'liable for any transaction failure caused by the User providing incorrect phone numbers, wrong Lightning '
            'invoices, wrong account details, or false information.\n\n'
            'Except where liability cannot be lawfully excluded, Chapsmart\'s aggregate liability shall not exceed the '
            'value of the specific transaction giving rise to the claim, less any applicable fees.'),

          // 17. System Availability
          _Section('17. System Availability, Security, and Maintenance',
            'Chapsmart implements industry-standard security measures including TLS encryption, rate limiting, '
            'reverse-proxy hardening, and application-layer access controls. We do not guarantee uninterrupted availability. '
            'We may suspend or change the Platform for maintenance, security incidents, regulatory requirements, '
            'or force majeure.'),

          // 18. Communication
          _Section('18. Communication',
            'When you use the Platform, you consent to receive communications from us electronically. '
            'If your contact details change, you are responsible for updating them.'),

          // 19. Dispute Resolution
          _Section('19. Dispute Resolution',
            'Any dispute shall initially be resolved through mutual negotiations in good faith. Contact us at '
            'support@chapsmart.com with a clear description of the dispute and relevant transaction details.\n\n'
            'If mutual negotiation fails within thirty (30) days, either party may refer the matter to the courts '
            'of Tanzania in accordance with Section 20.'),

          // 20. Governing Law
          _Section('20. Governing Law and Jurisdiction',
            'These Terms shall be governed by and construed in accordance with the laws of the United Republic of Tanzania. '
            'The parties submit to the exclusive jurisdiction of the courts of the United Republic of Tanzania.'),

          // 21. Intellectual Property
          _Section('21. Intellectual Property',
            'All copyright and intellectual property rights in the content and materials provided through the Platform '
            'are the proprietary property of Chapsmart or its licensors. You may not copy, modify, distribute, or use '
            'Chapsmart Materials without prior written consent.'),

          // 22. Amendments
          _Section('22. Amendments',
            'Chapsmart may revise these Terms at any time by updating this page. Changes become binding upon publication. '
            'For material changes, we will make reasonable efforts to notify users through the Platform or registered email.'),

          // 23. Customer Support
          _Section('23. Customer Support',
            '• Email: support@chapsmart.com\n'
            '• Response Time: We aim to respond within two (2) business days.\n'
            '• User Cooperation: Please provide accurate and complete information including your Account Number '
            'and relevant transaction references.'),

          // 24. Assignment
          _Section('24. Assignment',
            'Chapsmart may assign these Terms to any successor entity, affiliate, or acquirer without your consent. '
            'You may not assign these Terms without Chapsmart\'s prior written approval.'),

          // 25. Severability
          _Section('25. Severability',
            'If any provision of these Terms is held invalid, the remaining provisions continue in full force and effect.'),

          // 26. Entire Agreement
          _Section('26. Entire Agreement',
            'These Terms, together with Chapsmart\'s Privacy Policy, constitute the entire agreement between you and '
            'Chapsmart concerning your use of the Services. They supersede any prior agreements or communications.'),

          const SizedBox(height: 16),
          Text(
            'By registering a User Account and using Chapsmart Services, you confirm that you have read, understood, '
            'and accepted these Terms and Conditions in full.',
            style: TextStyle(fontSize: 13, color: C.t3, fontStyle: FontStyle.italic, height: 1.6),
          ),

          _WarningBox('General Notice: These Terms are a statement of Chapsmart\'s current operating framework and legal '
            'compliance posture. They do not constitute legal or financial advice. Users are encouraged to seek '
            'independent legal or financial advice where appropriate.'),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ─── Section header + body ───────────────────
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
        if (body.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(body, style: TextStyle(fontSize: 13.5, color: C.t2, height: 1.7)),
        ],
      ]),
    );
  }
}

// ─── Sub-section (4.x) ───────────────────
class _SubSection extends StatelessWidget {
  final String title, body;
  const _SubSection(this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: C.t1)),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 13.5, color: C.t2, height: 1.7)),
      ]),
    );
  }
}

// ─── Detail paragraph ───────────────────
class _Detail extends StatelessWidget {
  final String text;
  const _Detail(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: TextStyle(fontSize: 13.5, color: C.t2, height: 1.7)),
    );
  }
}

// ─── Info box (orange left border) ───────────────────
class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.btc.withOpacity(0.06),
        border: Border(left: BorderSide(color: C.btc, width: 4)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: C.t1, height: 1.6)),
    );
  }
}

// ─── Warning box (amber left border) ───────────────────
class _WarningBox extends StatelessWidget {
  final String text;
  const _WarningBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E8),
        border: const Border(left: BorderSide(color: Color(0xFFE8A838), width: 4)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: C.t1, height: 1.6)),
    );
  }
}

// ─── Service table ───────────────────
class _ServiceTable extends StatelessWidget {
  const _ServiceTable();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF0A0A0A),
          child: Row(children: [
            Expanded(child: Text('Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('Direction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5))),
          ]),
        ),
        _svcRow('Remittance', 'Bitcoin → M-Pesa (TZS)', false),
        _svcRow('Airtime', 'Bitcoin → Airtime', true),
        _svcRow('Buy Sats', 'M-Pesa (TZS) → Bitcoin', false),
      ]),
    );
  }

  Widget _svcRow(String svc, String dir, bool alt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: alt ? const Color(0xFFFAF8F5) : Colors.white,
      child: Row(children: [
        Expanded(child: Text(svc, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.t1))),
        Expanded(flex: 2, child: Text(dir, style: TextStyle(fontSize: 13, color: C.t2))),
      ]),
    );
  }
}

// ─── Fee table ───────────────────
class _FeeTable extends StatelessWidget {
  const _FeeTable();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          color: const Color(0xFF0A0A0A),
          child: Row(children: [
            Expanded(flex: 2, child: Text('Tier', style: _hdr)),
            Expanded(flex: 3, child: Text('Cumul. Spend', style: _hdr)),
            Expanded(flex: 2, child: Text('Fee', style: _hdr)),
            Expanded(flex: 2, child: Text('Tax', style: _hdr)),
            Expanded(flex: 2, child: Text('Total', style: _hdr)),
          ]),
        ),
        _feeRow('BRONZE', '0 – 5M TZS', '2.20%', '3%', '5.20%', const Color(0xFFF0E0CC), const Color(0xFF8B5E34), false),
        _feeRow('SILVER', '5M – 25M TZS', '1.87%', '3%', '4.87%', const Color(0xFFE8E8E8), const Color(0xFF555555), true),
        _feeRow('GOLD', '25M+ TZS', '1.32%', '3%', '4.32%', const Color(0xFFFFF3D0), const Color(0xFFA67C00), false),
      ]),
    );
  }

  TextStyle get _hdr => const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.4);

  Widget _feeRow(String tier, String spend, String fee, String tax, String total, Color badgeBg, Color badgeText, bool alt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: alt ? const Color(0xFFFAF8F5) : Colors.white,
      child: Row(children: [
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
          child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeText), textAlign: TextAlign.center),
        )),
        Expanded(flex: 3, child: Text(spend, style: TextStyle(fontSize: 12, color: C.t2))),
        Expanded(flex: 2, child: Text(fee, style: TextStyle(fontSize: 12, color: C.t2))),
        Expanded(flex: 2, child: Text(tax, style: TextStyle(fontSize: 12, color: C.t2))),
        Expanded(flex: 2, child: Text(total, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.t1))),
      ]),
    );
  }
}
