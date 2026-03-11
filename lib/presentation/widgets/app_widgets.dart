import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ─── App Logo ────────────────────────────────────────────
// Replace the Container below with Image.asset('assets/logo.png')
// when you have your logo file ready.

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with your logo image:
    // return Image.asset('assets/logo.png', width: size, height: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text('C',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.background,
              fontSize: size * 0.48,
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }
}

// ─── Gold Button ─────────────────────────────────────────

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: AppColors.background, strokeWidth: 2))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.background, size: 17),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.dmSans(
                  color: AppColors.background,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      ),
    );
  }
}

// ─── Tier Badge ──────────────────────────────────────────

class TierBadge extends StatelessWidget {
  final String tier;
  const TierBadge({super.key, required this.tier});

  Color get _color {
    switch (tier.toUpperCase()) {
      case 'GOLD':
        return AppColors.goldTier;
      case 'SILVER':
        return AppColors.silver;
      default:
        return AppColors.bronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(tier.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: _color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────

class StatsCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? accentColor;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = accentColor ?? AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }
}

// ─── Section Header ──────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ));
  }
}

// ─── Transaction Tile ────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final String recipientName, phoneNumber, status, type;
  final int amountTZS, sats;
  final DateTime date;

  const TransactionTile({
    super.key,
    required this.recipientName,
    required this.phoneNumber,
    required this.amountTZS,
    required this.sats,
    required this.status,
    required this.type,
    required this.date,
  });

  Color get _statusColor {
    if (status == 'settled' || status == 'SUCCESS') return AppColors.success;
    if (status == 'failed') return AppColors.error;
    return AppColors.warning;
  }

  IconData get _icon {
    if (type == 'airtime') return Icons.phone_android_rounded;
    if (type == 'buy-sats') return Icons.currency_bitcoin_rounded;
    return Icons.send_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(_icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    recipientName.isNotEmpty
                        ? recipientName
                        : type.replaceAll('-', ' ').toUpperCase(),
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if (phoneNumber.isNotEmpty)
                  Text(phoneNumber,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textMuted, fontSize: 11)),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('TZS ${_fmt(amountTZS)}',
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status,
                style: GoogleFonts.dmSans(
                    color: _statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
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
  final String label, value;
  const CopyField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 12)),
          ]),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied'), duration: const Duration(seconds: 1)),
            );
          },
          child: const Icon(Icons.copy_rounded,
              color: AppColors.textMuted, size: 14),
        ),
      ]),
    );
  }
}

// ─── Info Banner ─────────────────────────────────────────

class InfoBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const InfoBanner({
    super.key,
    required this.text,
    this.color = AppColors.info,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(color: color, fontSize: 11))),
      ]),
    );
  }
}

// ─── Glass Card ──────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const GlassCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}