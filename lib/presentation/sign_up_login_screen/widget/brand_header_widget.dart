import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandHeaderWidget extends StatelessWidget {
  const BrandHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.domain, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Sec Hostel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.exit_to_app_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Manage Leave,\nEffortlessly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Submit and track hostel leave requests.\nWardens approve with one tap.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
