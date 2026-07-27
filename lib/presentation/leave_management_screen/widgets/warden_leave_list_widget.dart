import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../widgets/empty_state_widget.dart';

class WardenLeaveListWidget extends StatelessWidget {
  final List<dynamic> requests;
  final Function(String) onApprove;
  final Function(String) onDecline;

  const WardenLeaveListWidget({
    required this.requests,
    required this.onApprove,
    required this.onDecline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.assignment_turned_in_outlined,
          title: 'No Requests Found',
          description: 'No leave requests match the selected filter.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _WardenLeaveCard(
            request: requests[index],
            index: index,
            onApprove: onApprove,
            onDecline: onDecline,
          ),
          childCount: requests.length,
        ),
      ),
    );
  }
}

class _WardenLeaveCard extends StatefulWidget {
  final dynamic request;
  final int index;
  final Function(String) onApprove;
  final Function(String) onDecline;

  const _WardenLeaveCard({
    required this.request,
    required this.index,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  State<_WardenLeaveCard> createState() => _WardenLeaveCardState();
}

class _WardenLeaveCardState extends State<_WardenLeaveCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + (widget.index * 50).clamp(0, 400)),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  LeaveStatus _parseStatus(String s) {
    switch (s) {
      case 'approved':
        return LeaveStatus.approved;
      case 'declined':
        return LeaveStatus.declined;
      default:
        return LeaveStatus.pending;
    }
  }

  IconData _leaveTypeIcon(String type) {
    switch (type) {
      case 'Medical':
        return Icons.local_hospital_outlined;
      case 'Family Event':
        return Icons.family_restroom_outlined;
      case 'Academic':
        return Icons.school_outlined;
      default:
        return Icons.person_outlined;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final req = widget.request;
    final status = req.status as String;
    final isPending = status == 'pending';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isPending
                ? Border.all(color: const Color(0xFFFDE68A), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(16),
              splashColor: theme.colorScheme.primaryContainer.withAlpha(77),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _leaveTypeIcon(req.leaveType as String),
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        req.studentName as String,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      StatusBadgeWidget(
                                        status: _parseStatus(status),
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.meeting_room_outlined,
                                        size: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Room ${req.roomNumber}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.bookmark_outline_rounded,
                                        size: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        req.leaveType as String,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatDate(req.fromDate as String)} – ${_formatDate(req.toDate as String)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Applied ${_formatDate(req.appliedOn as String)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      widget.onDecline(req.id as String),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Decline'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(
                                      color: Color(0xFFDC2626),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    textStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      widget.onApprove(req.id as String),
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    textStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _ExpandedDetail(request: req),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedDetail extends StatelessWidget {
  final dynamic request;

  const _ExpandedDetail({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Reason',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(request.reason as String, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _DetailChip(
                icon: Icons.phone_outlined,
                label: request.contactNumber as String,
              ),
              const SizedBox(width: 8),
              _DetailChip(
                icon: Icons.badge_outlined,
                label: request.id as String,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
