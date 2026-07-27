import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveLeaveCardWidget extends StatelessWidget {
  final dynamic request;

  const ActiveLeaveCardWidget({required this.request, super.key});

  Color _cardColor(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF1A56DB);
      case 'declined':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF1A56DB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request.status as String;
    final cardColor = _cardColor(context, status);
    final isPending = status == 'pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? 'In Progress' : status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatShortDate(request.fromDate as String),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            request.leaveType as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(request.fromDate as String)} → ${_formatDate(request.toDate as String)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isPending ? 0.4 : (status == 'approved' ? 1.0 : 0.0),
              backgroundColor: Colors.white.withAlpha(51),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Awaiting warden approval'
                : (status == 'approved'
                      ? 'Leave approved ✓'
                      : 'Leave declined'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parts[2]} ${months[int.parse(parts[1])]}';
  }

  String _formatShortDate(String dateStr) {
    final parts = dateStr.split('-');
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[int.parse(parts[1])].toUpperCase()} ${parts[2]}';
  }
}
