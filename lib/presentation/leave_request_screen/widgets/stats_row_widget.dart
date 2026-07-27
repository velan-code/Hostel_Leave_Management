import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsRowWidget extends StatelessWidget {
  final int total;
  final int approved;
  final int pending;

  const StatsRowWidget({
    required this.total,
    required this.approved,
    required this.pending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _StatTile(
          icon: Icons.assignment_outlined,
          value: '$total',
          label: 'Total\nSubmitted',
          iconColor: theme.colorScheme.primary,
          bgColor: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Icons.check_circle_outline_rounded,
          value: '$approved',
          label: 'Approved',
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Icons.hourglass_empty_rounded,
          value: '$pending',
          label: 'Pending',
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
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
