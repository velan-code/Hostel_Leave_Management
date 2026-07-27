import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LeaveStatus { pending, approved, declined, submitted }

class StatusBadgeWidget extends StatelessWidget {
  final LeaveStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: config.text,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(LeaveStatus s) {
    switch (s) {
      case LeaveStatus.pending:
        return _StatusConfig(
          bg: const Color(0xFFFEF3C7),
          dot: const Color(0xFFD97706),
          text: const Color(0xFF92400E),
          label: 'Pending',
        );
      case LeaveStatus.approved:
        return _StatusConfig(
          bg: const Color(0xFFDCFCE7),
          dot: const Color(0xFF16A34A),
          text: const Color(0xFF14532D),
          label: 'Approved',
        );
      case LeaveStatus.declined:
        return _StatusConfig(
          bg: const Color(0xFFFEE2E2),
          dot: const Color(0xFFDC2626),
          text: const Color(0xFF7F1D1D),
          label: 'Declined',
        );
      case LeaveStatus.submitted:
        return _StatusConfig(
          bg: const Color(0xFFEFF6FF),
          dot: const Color(0xFF1A56DB),
          text: const Color(0xFF1E3A8A),
          label: 'Submitted',
        );
    }
  }
}

class _StatusConfig {
  final Color bg, dot, text;
  final String label;
  const _StatusConfig({
    required this.bg,
    required this.dot,
    required this.text,
    required this.label,
  });
}
