import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ─── Gold Button ─────────────────────────────────────────

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;

  const GoldButton({super.key, required this.label, this.onTap, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2.5))
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.background, size: 18), const SizedBox(width: 8)],
              Text(label, style: GoogleFonts.dmSans(
                color: AppColors.background, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────

class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const StatsCard({super.key, required this.label, required this.value, required this.icon, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Tier Badge ──────────────────────────────────────────

class TierBadge extends StatelessWidget {
  final String tier;
  const TierBadge({super.key, required this.tier});

  Color get _tierColor {
    switch (tier.toUpperCase()) {
      case 'GOLD':   return AppColors.goldTier;
      case 'SILVER': return AppColors.silver;
      default:       return AppColors.bronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tierColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tierColor.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium_rounded, color: _tierColor, size: 13),
        const SizedBox(width: 4),
        Text(tier.toUpperCase(), style: GoogleFonts.dmSans(
          color: _tierColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        )),
      ]),
    );
  }
}

// ─── Section Header ──────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.dmSans(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
        )),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: GoogleFonts.dmSans(
              color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ),
      ],
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final String recipientName;
  final String phoneNumber;
  final int amountTZS;
  final int sats;
  final String status;
  final DateTime date;

  const TransactionTile({
    super.key, required this.recipientName, required this.phoneNumber,
    required this.amountTZS, required this.sats, required this.status, required this.date,
  });

  Color get _statusColor {
    switch (status) {
      case 'settled': return AppColors.success;
      case 'failed':  return AppColors.error;
      default:        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.gold, fontSize: 17, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(recipientName, style: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
          )),
          Text(phoneNumber, style: GoogleFonts.dmSans(
            color: AppColors.textSecondary, fontSize: 12,
          )),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('TZS ${_fmt(amountTZS)}', style: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: GoogleFonts.dmSans(
              color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4,
            )),
          ),
        ]),
      ]),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Copy Field ──────────────────────────────────────────

class CopyField extends StatelessWidget {
  final String label;
  final String value;

  const CopyField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.dmSans(
            color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.5,
          )),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 13,
            ),
          ),
        ])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.copy_rounded, color: AppColors.gold, size: 15),
          ),
        ),
      ]),
    );
  }
}

// ─── App Logo ────────────────────────────────────────────

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [BoxShadow(
          color: AppColors.gold.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      child: Center(
        child: Text('C', style: GoogleFonts.playfairDisplay(
          color: AppColors.background, fontSize: size * 0.52, fontWeight: FontWeight.w800,
        )),
      ),
    );
  }
}