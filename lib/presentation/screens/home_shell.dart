import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'remittance/remittance_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _screens = const [
    _DashboardTab(),
    RemittanceScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded),   label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.send_rounded),    label: 'Send'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded),  label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ───────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),

            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good morning,', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
                Text('ChapSmart', style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700,
                )),
              ]),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person_rounded, color: AppColors.textPrimary, size: 20),
                ),
              ),
            ]),

            const SizedBox(height: 28),

            // BTC Price Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1200), Color(0xFF2A1E00), Color(0xFF1A1200)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('BTC Price', style: GoogleFonts.dmSans(
                    color: AppColors.gold.withOpacity(0.7), fontSize: 12, letterSpacing: 0.5,
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('● LIVE', style: GoogleFonts.dmSans(
                      color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600,
                    )),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('\$68,420', style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700,
                )),
                Text('+2.4% today', style: GoogleFonts.dmSans(color: AppColors.success, fontSize: 13)),
                const SizedBox(height: 20),
                Row(children: [
                  _QuickStat(label: 'Rate', value: 'TZS 170,200/\$'),
                  const SizedBox(width: 24),
                  _QuickStat(label: '1 sat', value: '≈ TZS 0.11'),
                ]),
              ]),
            ),

            const SizedBox(height: 24),

            // Quick Action Button
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const Icon(Icons.send_rounded, color: AppColors.background, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Send Remittance', style: GoogleFonts.dmSans(
                    color: AppColors.background, fontSize: 15, fontWeight: FontWeight.w700,
                  )),
                  Text('Convert BTC to TZS instantly', style: GoogleFonts.dmSans(
                    color: AppColors.background.withOpacity(0.65), fontSize: 12,
                  )),
                ])),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.background, size: 20),
              ]),
            ),

            const SizedBox(height: 28),

            Text('How It Works', style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 14),

            ..._steps.asMap().entries.map((e) => _StepTile(
              step: e.key + 1, title: e.value.$1, desc: e.value.$2,
            )),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  static const _steps = [
    ('Create a Quote',    'Enter amount in TZS + recipient phone'),
    ('Lock the Price',    'Generate a Lightning invoice at live BTC rate'),
    ('Pay with Bitcoin',  'Send sats via any Lightning wallet'),
    ('Recipient Gets TZS','Funds arrive in seconds via Mobile Money'),
  ];
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(
        color: AppColors.gold.withOpacity(0.6), fontSize: 11, letterSpacing: 0.3,
      )),
      Text(value, style: GoogleFonts.dmSans(
        color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
      )),
    ],
  );
}

class _StepTile extends StatelessWidget {
  final int step;
  final String title, desc;
  const _StepTile({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withOpacity(0.12),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Center(child: Text('$step', style: GoogleFonts.dmSans(
            color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700,
          ))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
          )),
          Text(desc, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
        ])),
      ]),
    );
  }
}