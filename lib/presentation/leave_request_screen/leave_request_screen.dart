import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../models/leave_request_model.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../models/student_model.dart';
import '../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../widgets/notification_bell_widget.dart';
import '../profile_screen/profile_screen.dart';
import './widgets/leave_list_widget.dart';
import './widgets/submit_leave_bottom_sheet.dart';

import '../../services/sound_service.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
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

  void _addLeaveRequest(
    Map<String, dynamic> request,
    UserModel? currentUser,
    StudentModel matchedStudent,
  ) {
    FirebaseService().addLeaveRequest(
      studentName: matchedStudent.name.isNotEmpty
          ? matchedStudent.name
          : (currentUser?.name ?? 'Student'),
      rollNo: matchedStudent.rollNo.isNotEmpty
          ? matchedStudent.rollNo
          : (currentUser?.id ?? 'STU001'),
      type: (request['type'] as String?) ?? 'Home Visit',
      fromDate: (request['fromDate'] as String?) ?? '',
      toDate: (request['toDate'] as String?) ?? '',
      reason: (request['reason'] as String?) ?? '',
      assignedCcId: matchedStudent.assignedCcId,
      assignedCcName: matchedStudent.assignedCcName,
      assignedHodId: matchedStudent.assignedHodId,
      assignedHodName: matchedStudent.assignedHodName,
      assignedWardenId: matchedStudent.assignedWardenId,
      assignedWardenName: matchedStudent.assignedWardenName,
    );
    SoundService().playSuccess();
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.warningContainer,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are offline. Connect to internet to sync live data.',
              style: GoogleFonts.dmSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOffline = ref.watch(offlineStreamProvider).value ?? FirebaseService().isOffline;

    return StreamBuilder<List<StudentModel>>(
      stream: FirebaseService().studentsStream,
      initialData: FirebaseService().currentStudents,
      builder: (context, studentSnapshot) {
        final students = studentSnapshot.data ?? [];
        final matchedStudent = students.firstWhere(
          (s) =>
              (currentUser != null &&
                  s.email.toLowerCase() == currentUser.email.toLowerCase()) ||
              (currentUser != null &&
                  s.rollNo.toLowerCase() == currentUser.id.toLowerCase()),
          orElse: () => StudentModel(
            docId: '',
            id: currentUser?.id ?? '',
            name: currentUser?.name ?? '',
            email: currentUser?.email ?? '',
            department: 'Computer Science',
            year: (currentUser?.year.isNotEmpty == true) ? currentUser!.year : '3rd Year',
            roomNo: '101',
            hostelBlock: 'Block A',
            assignedWardenId: 'siva_sir',
            assignedWardenName: 'Siva Sir',
            assignedCcId: 'pradeepa_mam',
            assignedCcName: 'Pradeepa Mam',
            assignedHodId: 'kavitha_mam',
            assignedHodName: 'Kavitha Mam',
          ),
        );

        return StreamBuilder<List<LeaveRequestModel>>(
          stream: FirebaseService().leaveRequestsStream,
          initialData: FirebaseService().currentLeaveRequests,
          builder: (context, snapshot) {
            final allModels = snapshot.data ?? [];
            
            // Filter specifically for the logged-in student if profile is active
            final models = (currentUser != null && currentUser.id.isNotEmpty)
                ? allModels
                    .where((r) =>
                        r.rollNo.toLowerCase() == currentUser.id.toLowerCase() ||
                        (currentUser.name.isNotEmpty &&
                            r.studentName.toLowerCase() ==
                                currentUser.name.toLowerCase()))
                    .toList()
                : List<LeaveRequestModel>.from(allModels);

            models.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final leaveRequests = models.map((m) => m.toMap()).toList();

            final pendingCount =
                models.where((r) => r.status.toLowerCase().startsWith('pending')).length;
            final approvedCount =
                models.where((r) => r.status.toLowerCase() == 'approved').length;
            final declinedCount =
                models.where((r) => r.status.toLowerCase().startsWith('declined')).length;

            final blockingLeaveModel = models.firstWhere(
              (r) {
                final status = r.status.toLowerCase();
                if (status.startsWith('pending')) return true;
                if (status == 'approved') {
                  final permitStatus = _getPermitStatus(r);
                  if (permitStatus == 1 || permitStatus == 2) return true;
                }
                return false;
              },
              orElse: () => LeaveRequestModel(
                docId: '',
                id: '',
                studentName: '',
                rollNo: '',
                type: '',
                fromDate: '',
                toDate: '',
                reason: '',
                status: '',
                classMamSigned: false,
                hodSigned: false,
                wardenSigned: false,
                submittedOn: '',
              ),
            );
            final hasActiveRequest = blockingLeaveModel.docId.isNotEmpty;

            return Scaffold(
              backgroundColor: AppTheme.backgroundLight,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    if (isOffline)
                      SliverToBoxAdapter(
                        child: _buildOfflineBanner(),
                      ),
                    SliverToBoxAdapter(
                      child: _buildHeader(context, currentUser, matchedStudent),
                    ),
                SliverToBoxAdapter(
                  child: _buildStatsRow(
                    total: leaveRequests.length,
                    approved: approvedCount,
                    pending: pendingCount,
                    declined: declinedCount,
                  ),
                ),
                SliverToBoxAdapter(child: _buildActiveLeaveBanner(leaveRequests)),
                SliverToBoxAdapter(child: _buildStatusBannerCard(models)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                    child: Text(
                      'Leave History',
                      style: GoogleFonts.dmSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: LeaveListWidget(
                    requests: leaveRequests,
                    onItemTap: (reqMap) {
                      final reqId = (reqMap['docId'] as String?)?.isNotEmpty == true
                          ? reqMap['docId'] as String
                          : (reqMap['id'] as String? ?? '');
                      final model = LeaveRequestModel.fromMap(reqMap, reqId);
                      _showLeaveDetailBottomSheet(context, model);
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10.h)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _handleApplyForLeave(
              context,
              hasActiveRequest,
              blockingLeaveModel,
              currentUser,
              matchedStudent,
            ),
            backgroundColor: hasActiveRequest
                ? AppTheme.textSecondary
                : AppTheme.studentAccent,
            foregroundColor: Colors.white,
            icon: Icon(hasActiveRequest ? Icons.block_rounded : Icons.add_rounded),
            label: Text(
              hasActiveRequest
                  ? (blockingLeaveModel.status.toLowerCase().startsWith('pending')
                      ? 'Request Pending'
                      : 'Permit Active (Waiting)')
                  : 'Apply for Leave',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
            ),
          ),
        );
      },
    );
  },
);
  }

  void _handleApplyForLeave(
    BuildContext context,
    bool hasActiveRequest,
    LeaveRequestModel blockingReq,
    UserModel? currentUser,
    StudentModel matchedStudent,
  ) {
    if (hasActiveRequest) {
      final isPending = blockingReq.status.toLowerCase().startsWith('pending');
      final reqId = blockingReq.docId.isNotEmpty ? blockingReq.docId : blockingReq.id;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPending ? 'Active Request Pending' : 'Existing Permit Active',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            isPending
                ? 'You currently have a leave request pending approval. You cannot submit a new request until your current request is processed or cancelled.'
                : 'You already have an approved leave permit scheduled for (${blockingReq.fromDate} - ${blockingReq.toDate}). You cannot apply for a new leave until you cancel this existing permit.',
            style: GoogleFonts.dmSans(fontSize: 12.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmCancelRequest(context, reqId);
              },
              child: Text(
                'Cancel Existing Permit',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      _showSubmitSheet(context, currentUser, matchedStudent);
    }
  }

  void _confirmCancelRequest(BuildContext context, String reqId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Cancel Leave Request?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this pending leave request? Once cancelled, you will be able to submit a new leave request.',
          style: GoogleFonts.dmSans(fontSize: 12.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Request',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService().cancelLeaveRequest(reqId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Leave request cancelled successfully!',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            child: Text(
              'Cancel Request',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? currentUser, StudentModel matchedStudent) {
    final studentName = matchedStudent.name.isNotEmpty
        ? matchedStudent.name
        : (currentUser != null && currentUser.name.isNotEmpty ? currentUser.name : 'Student');
    final rollNo = matchedStudent.rollNo.isNotEmpty
        ? 'ERP no: ${matchedStudent.rollNo}'
        : (currentUser != null && currentUser.id.isNotEmpty ? 'ERP no: ${currentUser.id}' : 'Hostel Portal');

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.studentAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.0),
          bottomRight: Radius.circular(28.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back 👋',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                  Text(
                    studentName,
                    style: GoogleFonts.dmSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    rollNo,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.sp,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NotificationBellWidget(),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(studentDetails: matchedStudent),
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
                  const SizedBox(height: 8),
                  // ⚠️ Tiny Complaints Button below Notification and Profile
                  InkWell(
                    onTap: () => _showStudentComplaintsSidePanel(context, currentUser),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2A748),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE2A748).withAlpha(100),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.report_problem_rounded, color: Color(0xFF0F2440), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Complaints',
                            style: GoogleFonts.outfit(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F2440),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required int total,
    required int approved,
    required int pending,
    required int declined,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: total.toString(),
            color: AppTheme.primary,
          ),
          SizedBox(width: 2.w),
          _StatCard(
            label: 'Approved',
            value: approved.toString(),
            color: AppTheme.wardenAccent,
          ),
          SizedBox(width: 2.w),
          _StatCard(
            label: 'Pending',
            value: pending.toString(),
            color: AppTheme.warning,
          ),
          SizedBox(width: 2.w),
          _StatCard(
            label: 'Declined',
            value: declined.toString(),
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLeaveBanner(List<Map<String, dynamic>> requests) {
    final activeLeave = requests.firstWhere(
      (r) => (r['status'] as String? ?? '').toLowerCase().startsWith('pending'),
      orElse: () => {},
    );
    if (activeLeave.isEmpty) return const SizedBox.shrink();

    final reqId = (activeLeave['docId'] as String?)?.isNotEmpty == true
        ? activeLeave['docId'] as String
        : (activeLeave['id'] as String? ?? '');

    final activeLeaveModel = LeaveRequestModel.fromMap(
      activeLeave,
      reqId,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: GestureDetector(
        onTap: () => _showLeaveDetailBottomSheet(context, activeLeaveModel),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warning.withAlpha(26),
              AppTheme.warning.withAlpha(13),
            ],
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.warning.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(38),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Active Request',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  activeLeave['type'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${activeLeave['fromDate']} → ${activeLeave['toDate']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancelRequest(context, reqId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: Text(
                    'Cancel Request',
                    style: GoogleFonts.dmSans(fontSize: 9.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildApprovalProgress(activeLeave),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildApprovalProgress(Map<String, dynamic> leave) {
    final steps = [
      {'label': 'Class Mam', 'signed': leave['classMamSigned'] as bool},
      {'label': 'HOD', 'signed': leave['hodSigned'] as bool},
      {'label': 'Warden', 'signed': leave['wardenSigned'] as bool},
    ];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final prevSigned = steps[i ~/ 2]['signed'] as bool;
          return Expanded(
            child: Container(
              height: 2,
              color: prevSigned
                  ? AppTheme.wardenAccent
                  : const Color(0xFFCBD5E1),
            ),
          );
        }
        final step = steps[i ~/ 2];
        final signed = step['signed'] as bool;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: signed ? AppTheme.wardenAccent : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                signed
                    ? Icons.check_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: signed ? Colors.white : AppTheme.textSecondary,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step['label'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: signed ? AppTheme.wardenAccent : AppTheme.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  DateTime? _parseDateString(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    try {
      DateTime? parsed = DateTime.tryParse(dateStr.trim());
      if (parsed != null) return parsed;

      final parts = dateStr.trim().replaceAll(',', '').split(RegExp(r'[/\s\-]'));
      if (parts.length >= 3) {
        int? day;
        int? month;
        int? year;
        const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

        for (var p in parts) {
          final pLower = p.toLowerCase();
          final mIdx = months.indexWhere((m) => pLower.startsWith(m));
          if (mIdx != -1) {
            month = mIdx + 1;
          } else {
            final val = int.tryParse(p);
            if (val != null) {
              if (val > 1000) {
                year = val;
              } else if (day == null) {
                day = val;
              } else {
                month ??= val;
              }
            }
          }
        }

        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  int _getPermitStatus(LeaveRequestModel req) {
    // Returns:
    // 0: Expired / Not Approved
    // 1: Upcoming (Grey Card) - Approved but today < fromDate
    // 2: Active Today (Green Card) - Approved and fromDate <= today <= toDate
    if (req.status.toLowerCase() != 'approved') return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final fromD = _parseDateString(req.fromDate);
    final toD = _parseDateString(req.toDate);

    if (toD != null) {
      final toDay = DateTime(toD.year, toD.month, toD.day);
      if (today.isAfter(toDay)) {
        return 0;
      }
    }

    if (fromD != null) {
      final fromDay = DateTime(fromD.year, fromD.month, fromD.day);
      if (today.isBefore(fromDay)) {
        return 1;
      }
    }

    return 2;
  }

  Widget _buildStatusBannerCard(List<LeaveRequestModel> models) {
    if (models.isEmpty) return const SizedBox.shrink();

    final approvedList = models.where((r) => r.status.toLowerCase() == 'approved').toList();
    approvedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 1. Check for Active Today (Green Card)
    LeaveRequestModel? activeTodayLeave;
    for (var req in approvedList) {
      if (_getPermitStatus(req) == 2) {
        activeTodayLeave = req;
        break;
      }
    }

    if (activeTodayLeave != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
        child: GestureDetector(
          onTap: () => _showLeaveDetailBottomSheet(context, activeTodayLeave!),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(150), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You Have Permission for Today! 🎉',
                            style: GoogleFonts.dmSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            '${activeTodayLeave.type} • Valid Today',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            '${activeTodayLeave.fromDate} - ${activeTodayLeave.toDate}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.departure_board_rounded, size: 15, color: Color(0xFF059669)),
                                const SizedBox(width: 5),
                                Text(
                                  'Dep: ${activeTodayLeave.departureTime}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.flight_land_rounded, size: 15, color: Color(0xFF059669)),
                                const SizedBox(width: 5),
                                Text(
                                  'Arr: ${activeTodayLeave.arrivalTime}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Check for Upcoming Approved Leave (Green Border with Deep Grey Theme)
    LeaveRequestModel? upcomingLeave;
    for (var req in approvedList) {
      if (_getPermitStatus(req) == 1) {
        upcomingLeave = req;
        break;
      }
    }

    if (upcomingLeave != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
        child: GestureDetector(
          onTap: () => _showLeaveDetailBottomSheet(context, upcomingLeave!),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF10B981), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(50),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(51),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Permitted (Awaiting Date)',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Approved by CC, HOD & Warden • Starts ${upcomingLeave.fromDate}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(77)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF6EE7B7)),
                          const SizedBox(width: 6),
                          Text(
                            '${upcomingLeave.fromDate} - ${upcomingLeave.toDate}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.departure_board_rounded, size: 15, color: Color(0xFF6EE7B7)),
                                const SizedBox(width: 5),
                                Text(
                                  'Dep: ${upcomingLeave.departureTime}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.flight_land_rounded, size: 15, color: Color(0xFF6EE7B7)),
                                const SizedBox(width: 5),
                                Text(
                                  'Arr: ${upcomingLeave.arrivalTime}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🟢 Fully Permitted! Will activate in Green theme when leave date arrives.',
                          style: GoogleFonts.dmSans(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFA7F3D0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showLeaveDetailBottomSheet(BuildContext context, LeaveRequestModel model) {
    final isApproved = model.status.toLowerCase() == 'approved';
    final isDeclined = model.status.toLowerCase().contains('decline');
    final isPending = model.status.toLowerCase().startsWith('pending');
    final permitStatus = _getPermitStatus(model);

    String statusText = 'Pending Approval';
    Color statusColor = AppTheme.warning;
    IconData statusIcon = Icons.schedule_rounded;

    if (isApproved) {
      if (permitStatus == 2) {
        statusText = 'Permitted Today 🎉';
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.verified_user_rounded;
      } else if (permitStatus == 1) {
        statusText = 'Permitted (Awaiting Date)';
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.event_available_rounded;
      } else {
        statusText = 'Leave Completed';
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.check_circle_outline_rounded;
      }
    } else if (isDeclined) {
      statusText = 'Declined';
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel_rounded;
    }

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
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
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
                'Leave Request Details',
                style: GoogleFonts.dmSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Type: ${model.type}',
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.studentAccent,
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
                      backgroundColor: AppTheme.studentAccent,
                      radius: 20,
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.studentName.isNotEmpty ? model.studentName : 'Student',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'ERP no: ${model.rollNo}',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
                                'From Date',
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
                            model.fromDate,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Dept: ${model.departureTime}',
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
                                'To Date',
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
                            model.toDate,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF14532D),
                            ),
                          ),
                          Text(
                            'Return: ${model.arrivalTime}',
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
                  model.reason.isNotEmpty ? '"${model.reason}"' : '"No reason provided"',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.sp,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Approval Signatures Status:',
                style: GoogleFonts.dmSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildApprovalTile(
                roleName: 'Class Coordinator (Class Mam)',
                personName: model.assignedCcName.isNotEmpty ? model.assignedCcName : 'Class Coordinator',
                isSigned: model.classMamSigned,
              ),
              const SizedBox(height: 6),
              _buildApprovalTile(
                roleName: 'Head of Department (HOD)',
                personName: model.assignedHodName.isNotEmpty ? model.assignedHodName : 'HOD',
                isSigned: model.hodSigned,
              ),
              const SizedBox(height: 6),
              _buildApprovalTile(
                roleName: 'Hostel Warden',
                personName: model.assignedWardenName.isNotEmpty ? model.assignedWardenName : 'Warden',
                isSigned: model.wardenSigned,
              ),
              if (isDeclined && model.declineReason != null && model.declineReason!.isNotEmpty) ...[
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
                        '"${model.declineReason}"',
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
              if (isApproved || isPending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmCancelRequest(
                        context,
                        model.docId.isNotEmpty ? model.docId : model.id,
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                    label: Text(
                      'Cancel Leave Request',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalTile({
    required String roleName,
    required String personName,
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
                  roleName,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSigned ? const Color(0xFF14532D) : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  personName,
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

  void _showSubmitSheet(
    BuildContext context,
    UserModel? currentUser,
    StudentModel matchedStudent,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitLeaveBottomSheet(
        onSubmit: (req) => _addLeaveRequest(req, currentUser, matchedStudent),
        studentName: matchedStudent.name.isNotEmpty ? matchedStudent.name : currentUser?.name,
        rollNo: matchedStudent.rollNo.isNotEmpty ? matchedStudent.rollNo : currentUser?.id,
      ),
    );
  }

  void _showStudentComplaintsSidePanel(BuildContext context, UserModel? currentUser) {
    SoundService().playNotification();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: 85.h,
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2440),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: StreamBuilder<List<ComplaintModel>>(
              stream: FirebaseService().complaintsStream,
              initialData: FirebaseService().currentComplaints,
              builder: (context, snapshot) {
                final allComplaints = snapshot.data ?? [];
                final uId = currentUser?.id.trim().toLowerCase() ?? '';
                final uErp = currentUser?.erpNo.trim().toLowerCase() ?? '';
                final uEmail = currentUser?.email.trim().toLowerCase() ?? '';
                final uName = currentUser?.name.trim().toLowerCase() ?? '';

                final myComplaints = allComplaints.where((c) {
                  if (c.clearedByStudent) return false;
                  final cId = c.complainantId.trim().toLowerCase();
                  final cName = c.complainantName.trim().toLowerCase();
                  return (uId.isNotEmpty && cId == uId) ||
                      (uErp.isNotEmpty && cId == uErp) ||
                      (uEmail.isNotEmpty && cId == uEmail) ||
                      (uName.isNotEmpty && cName == uName);
                }).toList();

                final resolvedCount = myComplaints.where((c) => c.status.toLowerCase() == 'resolved').length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        const Icon(Icons.report_problem_rounded, color: Color(0xFFE2A748), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'My Complaints & Status',
                          style: GoogleFonts.dmSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // File New Complaint Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(AppRoutes.complaintScreen);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE2A748),
                            foregroundColor: const Color(0xFF0F2440),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text('File New', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 9.5.sp)),
                        ),
                        const Spacer(),
                        // Clear Resolved Button for Student
                        if (resolvedCount > 0)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final studentKey = uId.isNotEmpty ? uId : uName;
                              final cleared = await FirebaseService().clearStudentResolvedComplaints(studentKey);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cleared $cleared resolved complaints.'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                            label: Text('Clear Resolved ($resolvedCount)', style: GoogleFonts.dmSans(fontSize: 8.5.sp, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Expanded(
                      child: myComplaints.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.white.withAlpha(100)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No complaints found',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap "File New" to report food, water, or room issues directly to the Warden.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9.5.sp,
                                      color: Colors.white54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: myComplaints.length,
                              itemBuilder: (context, index) {
                                final complaint = myComplaints[index];
                                Color statusColor;
                                String statusText;
                                switch (complaint.status.toLowerCase()) {
                                  case 'resolved':
                                    statusColor = const Color(0xFF10B981);
                                    statusText = 'RESOLVED ✓';
                                    break;
                                  case 'in_progress':
                                    statusColor = const Color(0xFF3B82F6);
                                    statusText = 'IN PROGRESS ⚙️';
                                    break;
                                  default:
                                    statusColor = const Color(0xFFF59E0B);
                                    statusText = 'PENDING WARDEN REVIEW ⏳';
                                    break;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: statusColor.withAlpha(120), width: 1.2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withAlpha(40),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w800,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            complaint.category,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFE2A748),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Individual Delete option for student
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 18),
                                            onPressed: () async {
                                              await FirebaseService().deleteComplaint(complaint.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Complaint deleted.'),
                                                    backgroundColor: Colors.grey,
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        complaint.description,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10.sp,
                                          color: Colors.white.withAlpha(230),
                                        ),
                                      ),
                                      if (complaint.wardenRemarks != null && complaint.wardenRemarks!.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withAlpha(30),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                                          ),
                                          child: Text(
                                            'Warden Action: ${complaint.wardenRemarks}',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFA7F3D0),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
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
