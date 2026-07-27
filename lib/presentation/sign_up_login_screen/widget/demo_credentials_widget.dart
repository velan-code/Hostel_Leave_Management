import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DemoCredentialsWidget extends StatelessWidget {
  final String selectedRole;

  const DemoCredentialsWidget({required this.selectedRole, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudent = selectedRole == 'student';
    final email = isStudent
        ? 'senthil0velan@gmail.com'
        : 'warden.kapoor@hostel.edu';
    final password = isStudent ? 'student123' : 'warden123';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo ${isStudent ? 'Student' : 'Warden'} Credentials',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CredentialRow(label: 'Email', value: email),
          const SizedBox(height: 6),
          _CredentialRow(label: 'Password', value: password),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Icon(
            Icons.copy_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
