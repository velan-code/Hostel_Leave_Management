import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../models/leave_request_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/sound_service.dart';
import '../widgets/notification_bell_widget.dart';
import '../profile_screen/profile_screen.dart';

class HodDashboardScreen extends ConsumerStatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  ConsumerState<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends ConsumerState<HodDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRestoreSession();
  }

  Future<void> _checkAndRestoreSession() async {
    if (ref.read(currentUserProvider) == null) {
      final savedUser = await FirebaseService().loadSavedUserSession();
      if (savedUser != null && mounted) {
        ref.read(currentUserProvider.notifier).state = savedUser;
      }
    }
  }

  void _signRequest(String id, bool isCc) {
    SoundService().playSuccess();
    FirebaseService().updateLeaveRequestStatus(
      idOrDocId: id,
      newStatus: isCc ? 'pending_hod' : 'pending_warden',
      classMamSigned: isCc ? true : null,
      hodSigned: isCc ? null : true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCc ? 'Approved by CC! Request forwarded to HOD.' : 'Approved by HOD! Request forwarded to Warden.',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.hodAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void _declineRequest(String id, bool isCc) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          isCc ? 'Decline Request as CC?' : 'Decline Request as HOD?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify reason for declining this leave request:',
              style: GoogleFonts.dmSans(fontSize: 11.sp),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              SoundService().playDecline();
              await FirebaseService().updateLeaveRequestStatus(
                idOrDocId: id,
                newStatus: isCc ? 'declined_cc' : 'declined_hod',
                declineReason: reason,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Request declined and terminated.',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: Text('Decline Request', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isCc = currentUser != null &&
        (currentUser.role.toLowerCase() == 'cc' ||
            currentUser.role.toLowerCase() == 'class mam' ||
            currentUser.role.toLowerCase() == 'class coordinator' ||
            currentUser.role.toLowerCase() == 'class counselor');

    return StreamBuilder<List<LeaveRequestModel>>(
      stream: FirebaseService().leaveRequestsStream,
      initialData: FirebaseService().currentLeaveRequests,
      builder: (context, snapshot) {
        final models = snapshot.data ?? [];

        // Filter strictly by assigned staff & sequential stage (CC -> HOD)
        final assignedModels = models.where((r) {
          if (currentUser == null) return true;
          final uEmail = currentUser.email.trim().toLowerCase();
          if (isCc) {
            final matchesCc = r.assignedCcId == currentUser.id ||
                r.assignedCcId == currentUser.docId ||
                r.assignedCcId.isEmpty ||
                r.assignedCcName.isEmpty ||
                (uEmail.isNotEmpty && r.assignedCcName.toLowerCase().contains(uEmail.split('@').first)) ||
                (currentUser.name.isNotEmpty && r.assignedCcName.toLowerCase() == currentUser.name.toLowerCase()) ||
                (r.assignedCcName.isNotEmpty && currentUser.name.toLowerCase().contains(r.assignedCcName.toLowerCase())) ||
                (currentUser.name.isNotEmpty && r.assignedCcName.toLowerCase().contains(currentUser.name.toLowerCase()));
            return matchesCc;
          } else {
            final matchesHod = r.assignedHodId == currentUser.id ||
                r.assignedHodId == currentUser.docId ||
                r.assignedHodId.isEmpty ||
                r.assignedHodName.isEmpty ||
                (uEmail.isNotEmpty && r.assignedHodName.toLowerCase().contains(uEmail.split('@').first)) ||
                (currentUser.name.isNotEmpty && r.assignedHodName.toLowerCase() == currentUser.name.toLowerCase()) ||
                (r.assignedHodName.isNotEmpty && currentUser.name.toLowerCase().contains(r.assignedHodName.toLowerCase())) ||
                (currentUser.name.isNotEmpty && r.assignedHodName.toLowerCase().contains(currentUser.name.toLowerCase()));
            // HOD ONLY sees requests approved by CC (classMamSigned == true)
            return matchesHod && r.classMamSigned;
          }
        }).toList();

        // Sort: Pending requests waiting for approval at TOP of queue, followed by timestamp
        assignedModels.sort((a, b) {
          final isADeclined = a.status.toLowerCase().startsWith('declined');
          final isBDeclined = b.status.toLowerCase().startsWith('declined');
          final aIsPending = isCc ? (!a.classMamSigned && !isADeclined) : (a.classMamSigned && !a.hodSigned && !isADeclined);
          final bIsPending = isCc ? (!b.classMamSigned && !isBDeclined) : (b.classMamSigned && !b.hodSigned && !isBDeclined);

          if (aIsPending && !bIsPending) return -1;
          if (!aIsPending && bIsPending) return 1;

          return b.createdAt.compareTo(a.createdAt);
        });
        final requests = assignedModels.map((m) => m.toMap()).toList();

        final pendingCount = assignedModels.where((r) {
          final isDeclined = r.status.toLowerCase().startsWith('declined');
          if (isCc) {
            return !r.classMamSigned && !isDeclined;
          } else {
            return r.classMamSigned && !r.hodSigned && !isDeclined;
          }
        }).length;

        final signedCount = assignedModels.where((r) => isCc ? r.classMamSigned : r.hodSigned).length;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, pendingCount, currentUser),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  child: Row(
                    children: [
                      _MiniStat(
                        label: 'Total Assigned',
                        value: requests.length.toString(),
                        color: AppTheme.hodAccent,
                      ),
                      SizedBox(width: 3.w),
                      _MiniStat(
                        label: 'Pending Action',
                        value: pendingCount.toString(),
                        color: AppTheme.warning,
                      ),
                      SizedBox(width: 3.w),
                      _MiniStat(
                        label: 'Approved by Me',
                        value: signedCount.toString(),
                        color: AppTheme.wardenAccent,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isCc ? 'CC Approval Queue (Step 1)' : 'HOD Approval Queue (Step 2)',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: requests.length,
                    itemBuilder: (_, i) {
                      final req = requests[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.5.h),
                        child: _HodLeaveCard(
                          request: req,
                          isCc: isCc,
                          onSign: () => _signRequest(req['docId'] ?? req['id'], isCc),
                          onDecline: () => _declineRequest(req['docId'] ?? req['id'], isCc),
                          onTapCard: () => _showRequestDetailBottomSheet(context, req, isCc),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int pendingCount, UserModel? currentUser) {
    final roleTitle = (currentUser != null && currentUser.role.isNotEmpty)
        ? '${currentUser.role} Dashboard'
        : 'HOD / Class Mam Dashboard';
    final userName = (currentUser != null && currentUser.name.isNotEmpty)
        ? currentUser.name
        : 'Faculty';

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.hodAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.0),
          bottomRight: Radius.circular(28.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$userName  •  $pendingCount awaiting signature',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const NotificationBellWidget(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetailBottomSheet(
    BuildContext context,
    Map<String, dynamic> request,
    bool isCc,
  ) {
    final statusStr = (request['status'] as String? ?? '').toLowerCase();
    final isDeclined = statusStr.startsWith('declined');
    final classMamSigned = request['classMamSigned'] as bool? ?? false;
    final hodSigned = request['hodSigned'] as bool? ?? false;
    final wardenSigned = request['wardenSigned'] as bool? ?? false;
    final isSignedByMe = isCc ? classMamSigned : hodSigned;
    final canApproveOrDecline = !isSignedByMe && !isDeclined && statusStr != 'approved' && statusStr != 'cancelled';

    final reqId = (request['docId'] as String?)?.isNotEmpty == true
        ? request['docId'] as String
        : (request['id'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDeclined
                          ? AppTheme.error.withAlpha(30)
                          : (isSignedByMe
                              ? AppTheme.wardenAccent.withAlpha(30)
                              : AppTheme.warning.withAlpha(30)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDeclined
                          ? 'DECLINED'
                          : (isSignedByMe ? 'APPROVED BY YOU' : 'PENDING YOUR APPROVAL'),
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDeclined
                            ? AppTheme.error
                            : (isSignedByMe ? AppTheme.wardenAccent : AppTheme.warning),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Approval Request Details',
                style: GoogleFonts.dmSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Leave Type: ${request['type'] ?? 'Outing'}',
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.hodAccent,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.hodAccent,
                      radius: 20,
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['studentName'] as String? ?? 'Student',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'ERP no: ${request['rollNo'] ?? '814425149012'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Dept: ${request['department'] ?? 'Computer Science'}  •  Block: ${request['hostelBlock'] ?? 'A'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                'Departure Date',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request['fromDate'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Time: ${request['departureTime'] ?? '04:20 PM'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.sp,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_repeat_rounded, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                'Arrival Date',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request['toDate'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF14532D),
                            ),
                          ),
                          Text(
                            'Time: ${request['arrivalTime'] ?? '09:00 AM'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.sp,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for Leave:',
                style: GoogleFonts.dmSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  request['reason'] as String? ?? 'No reason provided',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Approval Signatures Chain:',
                style: GoogleFonts.dmSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildAuthoritySignatureTile(
                role: 'Class Coordinator (Class Mam)',
                name: request['assignedCcName'] as String? ?? 'Pradeepa Mam',
                isSigned: classMamSigned,
              ),
              const SizedBox(height: 6),
              _buildAuthoritySignatureTile(
                role: 'Head of Department (HOD)',
                name: request['assignedHodName'] as String? ?? 'Kavitha Mam',
                isSigned: hodSigned,
              ),
              const SizedBox(height: 6),
              _buildAuthoritySignatureTile(
                role: 'Hostel Warden',
                name: request['assignedWardenName'] as String? ?? 'Siva Sir',
                isSigned: wardenSigned,
              ),
              if (request['declineReason'] != null && (request['declineReason'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decline Reason:',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${request['declineReason']}"',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.sp,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (canApproveOrDecline)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _declineRequest(reqId, isCc);
                        },
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        label: Text(
                          'Decline Request',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5.sp,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.hodAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _signRequest(reqId, isCc);
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Approve & Sign',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthoritySignatureTile({
    required String role,
    required String name,
    required bool isSigned,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSigned ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSigned ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSigned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isSigned ? const Color(0xFF16A34A) : AppTheme.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSigned ? const Color(0xFF14532D) : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 8.5.sp,
                    color: isSigned ? const Color(0xFF166534) : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSigned ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSigned ? 'Signed ✓' : 'Pending',
              style: GoogleFonts.dmSans(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                color: isSigned ? const Color(0xFF15803D) : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HodLeaveCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isCc;
  final VoidCallback onSign;
  final VoidCallback onDecline;
  final VoidCallback onTapCard;

  const _HodLeaveCard({
    required this.request,
    required this.isCc,
    required this.onSign,
    required this.onDecline,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final classMamSigned = request['classMamSigned'] as bool? ?? false;
    final hodSigned = request['hodSigned'] as bool? ?? false;
    final statusStr = (request['status'] as String? ?? '').toLowerCase();
    final isDeclined = statusStr.startsWith('declined');
    final isSignedByMe = isCc ? classMamSigned : hodSigned;

    return GestureDetector(
      onTap: onTapCard,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.hodAccent.withAlpha(26),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.hodAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['studentName'] as String? ?? 'Student',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${request['rollNo'] ?? ''}  •  ${request['type'] ?? ''}',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDeclined
                      ? AppTheme.error.withAlpha(26)
                      : (isSignedByMe
                          ? AppTheme.wardenAccent.withAlpha(26)
                          : AppTheme.warning.withAlpha(26)),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isDeclined
                      ? 'DECLINED'
                      : (isSignedByMe ? 'APPROVED' : 'PENDING'),
                  style: GoogleFonts.dmSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: isDeclined
                        ? AppTheme.error
                        : (isSignedByMe ? AppTheme.wardenAccent : AppTheme.warning),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
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
                  size: 13,
                  color: AppTheme.hodAccent,
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
              color: AppTheme.hodAccent.withAlpha(18),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppTheme.hodAccent.withAlpha(77),
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
                      color: AppTheme.hodAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reason for Leave:',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.hodAccent,
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
          if (request['declineReason'] != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reason: ${request['declineReason']}',
                style: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.error),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _SigBadge(
                label: 'Class Mam / CC',
                signed: classMamSigned,
              ),
              const SizedBox(width: 6),
              _SigBadge(label: 'HOD', signed: hodSigned),
            ],
          ),
          if (!isSignedByMe && !isDeclined) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Decline',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSign,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      isCc ? 'Approve (CC)' : 'Approve (HOD)',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.hodAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _SigBadge extends StatelessWidget {
  final String label;
  final bool signed;
  const _SigBadge({required this.label, required this.signed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: signed ? AppTheme.wardenAccent : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: signed ? AppTheme.wardenAccent : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
