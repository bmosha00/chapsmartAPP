import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

// ─── Primary CTA ─────────────────────────────────────────
class Btn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final bool loading, enabled; final IconData? icon;
  const Btn({super.key, required this.label, this.onTap, this.loading = false, this.enabled = true, this.icon});
  @override
  Widget build(BuildContext context) {
    final ok = enabled && !loading;
    return GestureDetector(onTap: ok ? onTap : null, child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 52, width: double.infinity,
        decoration: BoxDecoration(color: ok ? C.t1 : C.t1.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
        child: Center(child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ]))));
  }
}

// ─── Secondary button ────────────────────────────────────
class BtnSecondary extends StatelessWidget {
  final String label; final VoidCallback? onTap; final IconData? icon;
  const BtnSecondary({super.key, required this.label, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(height: 52, width: double.infinity,
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: C.t2, size: 16), const SizedBox(width: 8)],
          Text(label, style: TextStyle(color: C.t2, fontSize: 15, fontWeight: FontWeight.w600)),
        ]))));
  }
}

// ─── Stat card ───────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label, value; final String? sub; final Color? valueColor;
  const StatCard({super.key, required this.label, required this.value, this.sub, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border), boxShadow: [C.shadow]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.t3, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: valueColor ?? C.t1)),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: TextStyle(fontSize: 11, color: C.t3))),
        ]));
  }
}

// ─── Tier badge ──────────────────────────────────────────
class TierBadge extends StatelessWidget {
  final String tier;
  const TierBadge({super.key, required this.tier});
  Color get _c { switch (tier.toUpperCase()) { case 'GOLD': return C.gold; case 'SILVER': return C.silver; default: return C.bronze; } }
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: C.btc.withOpacity(0.08), borderRadius: BorderRadius.circular(99), border: Border.all(color: C.btc.withOpacity(0.15))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: _c), const SizedBox(width: 4),
          Text(tier.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.btcDark)),
        ]));
  }
}

// ─── Transaction tile ────────────────────────────────────
class TxTile extends StatelessWidget {
  final String title, detail, amount, time, status; final IconData icon; final Color color;
  const TxTile({super.key, required this.title, required this.detail, required this.amount, required this.time, required this.status, required this.icon, required this.color});
  Color get _sc { if (status == 'completed' || status == 'settled' || status == 'SUCCESS') return C.green; if (status == 'failed') return C.red; return C.btc; }
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border), boxShadow: [C.shadow]),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.t1)),
            Text(detail, style: TextStyle(fontSize: 11, color: C.t3), overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'SpaceMono', color: C.t1)),
            const SizedBox(height: 2),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: _sc.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _sc))),
          ]),
        ]));
  }
}

// ─── Copy field ──────────────────────────────────────────
class CopyField extends StatelessWidget {
  final String label, value;
  const CopyField({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied'), backgroundColor: C.t1, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 1))); },
        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: C.t3)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 11, fontFamily: 'SpaceMono', color: C.t1), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Icon(Icons.copy_rounded, color: C.t3, size: 14),
            ])));
  }
}

// ─── Hint ────────────────────────────────────────────────
class Hint extends StatelessWidget {
  final String text; final IconData icon; final Color? color;
  const Hint({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? C.btc;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: c.withOpacity(0.6), size: 15), const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: c.withOpacity(0.7), height: 1.4))),
        ]));
  }
}

// ─── Back button ─────────────────────────────────────────
class BackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const BackBtn({super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap ?? () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: C.card, shape: BoxShape.circle, border: Border.all(color: C.border)),
            child: Icon(Icons.arrow_back_rounded, color: C.t2, size: 18)));
  }
}

// ─── Section header ──────────────────────────────────────
class SecHead extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction;
  const SecHead({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.t1)),
      if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.btc))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// STEP TRACKER — shows payment lifecycle steps
// ═══════════════════════════════════════════════════════════
class StepTracker extends StatelessWidget {
  final List<StepItem> steps;
  final int currentStep;
  const StepTracker({super.key, required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepRow(step: steps[i], index: i, currentStep: currentStep, isLast: i == steps.length - 1),
          if (i < steps.length - 1) _StepLine(done: i < currentStep),
        ],
      ]),
    );
  }
}

class StepItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const StepItem({required this.title, required this.subtitle, required this.icon, required this.color});
}

class _StepRow extends StatelessWidget {
  final StepItem step; final int index, currentStep; final bool isLast;
  const _StepRow({required this.step, required this.index, required this.currentStep, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isActive = index == currentStep;
    final isPending = index > currentStep;

    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDone ? C.green.withOpacity(0.1) : isActive ? step.color.withOpacity(0.1) : C.bg,
          shape: BoxShape.circle,
          border: Border.all(color: isDone ? C.green.withOpacity(0.3) : isActive ? step.color.withOpacity(0.3) : C.border),
        ),
        child: Center(child: isDone
            ? const Icon(Icons.check_rounded, color: C.green, size: 18)
            : isActive
            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: step.color))
            : Icon(step.icon, color: C.t3, size: 16)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isPending ? C.t3 : C.t1)),
        Text(step.subtitle, style: TextStyle(fontSize: 12, color: isPending ? C.t3.withOpacity(0.6) : C.t3)),
      ])),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 17),
        child: Container(width: 2, height: 24, decoration: BoxDecoration(
          color: done ? C.green.withOpacity(0.3) : C.border,
          borderRadius: BorderRadius.circular(1),
        )));
  }
}

// ═══════════════════════════════════════════════════════════
// SUCCESS SHEET — bottom sheet celebration
// ═══════════════════════════════════════════════════════════
class SuccessSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? detail;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  final VoidCallback onButton;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const SuccessSheet({
    super.key,
    required this.title,
    required this.message,
    this.detail,
    this.icon = Icons.check_rounded,
    this.color = C.green,
    required this.buttonLabel,
    required this.onButton,
    this.secondaryLabel,
    this.onSecondary,
  });

  static void show(BuildContext context, {
    required String title,
    required String message,
    String? detail,
    IconData icon = Icons.check_rounded,
    Color color = C.green,
    required String buttonLabel,
    required VoidCallback onButton,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    showModalBottomSheet(
      context: context, isDismissible: false, enableDrag: false,
      backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => SuccessSheet(title: title, message: message, detail: detail, icon: icon, color: color, buttonLabel: buttonLabel, onButton: onButton, secondaryLabel: secondaryLabel, onSecondary: onSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 28),
        Container(width: 72, height: 72, decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 36)),
        const SizedBox(height: 20),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.t1), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 14, color: C.t3, height: 1.5), textAlign: TextAlign.center),
        if (detail != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, color: color, size: 16), const SizedBox(width: 8),
                Flexible(child: Text(detail!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
              ])),
        ],
        const SizedBox(height: 24),
        Btn(label: buttonLabel, onTap: onButton),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 10),
          BtnSecondary(label: secondaryLabel!, onTap: onSecondary),
        ],
      ]),
    );
  }
}