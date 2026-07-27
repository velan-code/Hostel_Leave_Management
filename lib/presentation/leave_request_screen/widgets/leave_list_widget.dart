import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class LeaveListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final void Function(Map<String, dynamic> req)? onItemTap;
  const LeaveListWidget({super.key, required this.requests, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 48,
                  color: AppTheme.textSecondary.withAlpha(102),
                ),
                SizedBox(height: 1.h),
                Text(
                  'No leave requests yet',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final req = requests[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: _LeaveCard(
            request: req,
            onTap: onItemTap != null ? () => onItemTap!(req) : null,
          ),
        );
      }, childCount: requests.length),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onTap;
  const _LeaveCard({required this.request, this.onTap});

  Color get _statusColor {
    final s = (request['status'] as String? ?? '').toLowerCase();
    if (s == 'approved') return AppTheme.wardenAccent;
    if (s.startsWith('declined') || s == 'cancelled') return AppTheme.error;
    return AppTheme.warning;
  }

  String get _statusLabel {
    final s = (request['status'] as String? ?? '').toLowerCase();
    if (s == 'approved') return 'Approved';
    if (s == 'cancelled') return 'Cancelled';
    if (s.startsWith('declined')) return 'Declined';
    if (s == 'pending_cc') return 'Pending CC';
    if (s == 'pending_hod') return 'Pending HOD';
    if (s == 'pending_warden') return 'Pending Warden';
    return 'Pending';
  }

  IconData get _statusIcon {
    final s = (request['status'] as String? ?? '').toLowerCase();
    if (s == 'approved') return Icons.check_circle_rounded;
    if (s.startsWith('declined') || s == 'cancelled') return Icons.cancel_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.studentAccent.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  request['type'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.studentAccent,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 12, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${request['fromDate']} → ${request['toDate']}',
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (request['departureTime'] != null || request['arrivalTime'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppTheme.studentAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dep: ${request['departureTime'] ?? '09:00 AM'}  •  Arr: ${request['arrivalTime'] ?? '06:00 PM'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.studentAccent.withAlpha(18),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppTheme.studentAccent.withAlpha(77),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.note_alt_rounded,
                      size: 14,
                      color: AppTheme.studentAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reason for Leave:',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.studentAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  request['reason'] as String? ?? 'No reason provided',
                  style: GoogleFonts.dmSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if ((request['status'] as String? ?? '').startsWith('declined') &&
              request['declineReason'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request['declineReason'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildSignatureRow(),
        ],
      ),
    ),
    );
  }

  Widget _buildSignatureRow() {
    final signatures = [
      {'label': 'Class Mam', 'signed': request['classMamSigned'] as bool},
      {'label': 'HOD', 'signed': request['hodSigned'] as bool},
      {'label': 'Warden', 'signed': request['wardenSigned'] as bool},
    ];
    return Row(
      children: signatures.map((sig) {
        final signed = sig['signed'] as bool;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: signed
                  ? AppTheme.wardenAccent.withAlpha(26)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: signed
                    ? AppTheme.wardenAccent.withAlpha(77)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  signed ? Icons.draw_rounded : Icons.edit_off_rounded,
                  size: 10,
                  color: signed
                      ? AppTheme.wardenAccent
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  sig['label'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: signed
                        ? AppTheme.wardenAccent
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
