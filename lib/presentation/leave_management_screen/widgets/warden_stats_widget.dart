import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WardenStatsWidget extends StatelessWidget {
  final int pending;
  final int approved;
  final int declined;

  const WardenStatsWidget({
    required this.pending,
    required this.approved,
    required this.declined,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '$pending',
          label: 'Pending\nReview',
          icon: Icons.pending_actions_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          isAlert: pending > 0,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$approved',
          label: 'Approved\nThis Month',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$declined',
          label: 'Declined\nThis Month',
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEE2E2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isAlert;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isAlert
              ? Border.all(color: const Color(0xFFFDE68A), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
