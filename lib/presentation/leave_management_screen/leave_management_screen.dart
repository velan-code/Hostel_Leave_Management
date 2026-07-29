import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';
import '../../models/leave_request_model.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/sound_service.dart';
import '../widgets/notification_bell_widget.dart';
import '../profile_screen/profile_screen.dart';

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen> {
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

  int _activeTab = 0; // 0 = Leave Approvals, 1 = Student Complaints, 2 = Attendance & Monitor Log
  String _filter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Declined'];

  String _complaintFilter = 'All';
  final List<String> _complaintFilters = ['All', 'Pending', 'In Progress', 'Resolved'];

  String _attendanceTimeframe = 'Day'; // 'Day', 'Week', 'Month'
  String _attendanceStatusFilter = 'All'; // 'All', 'Present', 'Absent'
  String _attendanceSearchQuery = '';
  final TextEditingController _attendanceSearchController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _attendanceSearchController.dispose();
    super.dispose();
  }

  void _approve(String id) {
    SoundService().playSuccess();
    FirebaseService().updateLeaveRequestStatus(
      idOrDocId: id,
      newStatus: 'approved',
      wardenSigned: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Leave request approved successfully!',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.wardenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void _showDeclineDialog(String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Decline Leave Request',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for declining:',
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter decline reason...',
                hintStyle: GoogleFonts.dmSans(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _decline(
                id,
                reasonController.text.trim().isEmpty
                    ? 'No reason provided'
                    : reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _decline(String id, String reason) {
    SoundService().playDecline();
    FirebaseService().updateLeaveRequestStatus(
      idOrDocId: id,
      newStatus: 'declined_warden',
      declineReason: reason,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Leave request declined.',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return StreamBuilder<List<LeaveRequestModel>>(
      stream: FirebaseService().leaveRequestsStream,
      initialData: FirebaseService().currentLeaveRequests,
      builder: (context, requestsSnapshot) {
        final models = requestsSnapshot.data ?? [];

        // Filter strictly for Warden assigned requests approved by CC and HOD
        final wardenModels = models.where((r) {
          if (currentUser == null) return true;
          final uEmail = currentUser.email.trim().toLowerCase();
          final matchesWarden = r.assignedWardenId == currentUser.id ||
              r.assignedWardenId == currentUser.docId ||
              r.assignedWardenId.isEmpty ||
              r.assignedWardenName.isEmpty ||
              (uEmail.isNotEmpty && r.assignedWardenName.toLowerCase().contains(uEmail.split('@').first)) ||
              (currentUser.name.isNotEmpty && r.assignedWardenName.toLowerCase() == currentUser.name.toLowerCase()) ||
              (r.assignedWardenName.isNotEmpty && currentUser.name.toLowerCase().contains(r.assignedWardenName.toLowerCase())) ||
              (currentUser.name.isNotEmpty && r.assignedWardenName.toLowerCase().contains(currentUser.name.toLowerCase()));
          // Warden ONLY sees requests approved by BOTH CC and HOD
          return matchesWarden && r.classMamSigned && r.hodSigned;
        }).toList();

        // Sort: Pending requests waiting for Warden approval at TOP, followed by timestamp
        wardenModels.sort((a, b) {
          final aIsPending = !a.wardenSigned && !a.status.toLowerCase().startsWith('declined') && a.status.toLowerCase() != 'approved' && a.status.toLowerCase() != 'cancelled';
          final bIsPending = !b.wardenSigned && !b.status.toLowerCase().startsWith('declined') && b.status.toLowerCase() != 'approved' && b.status.toLowerCase() != 'cancelled';

          if (aIsPending && !bIsPending) return -1;
          if (!aIsPending && bIsPending) return 1;

          return b.createdAt.compareTo(a.createdAt);
        });
        final requests = wardenModels.map((m) => m.toMap()).toList();

        return StreamBuilder<List<ComplaintModel>>(
          stream: FirebaseService().complaintsStream,
          initialData: FirebaseService().currentComplaints,
          builder: (context, complaintsSnapshot) {
            final allComplaints = complaintsSnapshot.data ?? [];
            final pendingComplaintsCount =
                allComplaints.where((c) => c.status.toLowerCase() == 'pending').length;

            return StreamBuilder<List<UserModel>>(
              stream: FirebaseService().usersStream,
              initialData: FirebaseService().currentUsers,
              builder: (context, usersSnapshot) {
                final users = usersSnapshot.data ?? [];
                final studentUsers = users.where((u) => u.role.toLowerCase() == 'student').toList();

                return StreamBuilder<List<StudentModel>>(
                  stream: FirebaseService().studentsStream,
                  initialData: FirebaseService().currentStudents,
                  builder: (context, studentsSnapshot) {
                    final studentsList = studentsSnapshot.data ?? [];

                    final totalStudentsCount = studentUsers.isNotEmpty ? studentUsers.length : 3;
                    final approvedLeaveRequests = wardenModels.where((r) => r.status.toLowerCase() == 'approved').toList();
                    final onLeaveCount = approvedLeaveRequests.length;
                    final presentInHostelCount = (totalStudentsCount - onLeaveCount) < 0 ? 0 : (totalStudentsCount - onLeaveCount);

                    final filtered = _filter == 'All'
                        ? requests
                        : requests
                            .where((r) {
                                final s = r['status'].toString().toLowerCase();
                                switch (_filter) {
                                  case 'Pending':
                                    return s.startsWith('pending');
                                  case 'Approved':
                                    return s == 'approved';
                                  case 'Declined':
                                    return s.startsWith('declined');
                                  default:
                                    return true;
                                }
                              })
                            .toList();

                    final pendingCount =
                        wardenModels.where((r) => !r.wardenSigned && !r.status.toLowerCase().startsWith('declined')).length;

                    return Scaffold(
                      backgroundColor: AppTheme.backgroundLight,
                      body: SafeArea(
                        child: Column(
                          children: [
                            _buildHeader(context, pendingCount, currentUser),
                            _buildTabToggle(pendingComplaintsCount),
                            if (_activeTab == 0) ...[
                              _buildOccupancyCards(
                                totalStudents: totalStudentsCount,
                                presentInHostel: presentInHostelCount,
                                onLeave: onLeaveCount,
                              ),
                              _buildFilterChips(),
                              Expanded(
                                child: filtered.isEmpty
                                    ? _buildEmpty()
                                    : ListView.builder(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                          vertical: 1.h,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (_, i) {
                                          final req = filtered[i];
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 1.5.h),
                                            child: _WardenLeaveCard(
                                              request: req,
                                              onApprove: () => _approve(req['docId'] ?? req['id']),
                                              onDecline: () =>
                                                  _showDeclineDialog(req['docId'] ?? req['id']),
                                              onTapCard: () => _showWardenDetailBottomSheet(context, req),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ] else if (_activeTab == 1) ...[
                              Expanded(
                                child: _buildComplaintsTab(allComplaints),
                              ),
                            ] else ...[
                              Expanded(
                                child: _buildAttendanceTab(
                                  studentUsers: studentUsers,
                                  allStudents: studentsList,
                                  allRequests: wardenModels,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOccupancyCards({
    required int totalStudents,
    required int presentInHostel,
    required int onLeave,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                const Icon(
                  Icons.night_shelter_rounded,
                  color: AppTheme.wardenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hostel Occupancy & Attendance Status',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OccupancyStat(
                    label: 'Total Students',
                    value: totalStudents.toString(),
                    color: AppTheme.primary,
                    icon: Icons.people_outline_rounded,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _OccupancyStat(
                    label: 'Present in Hostel',
                    value: presentInHostel.toString(),
                    color: AppTheme.wardenAccent,
                    icon: Icons.home_work_rounded,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _OccupancyStat(
                    label: 'On Leave',
                    value: onLeave.toString(),
                    color: AppTheme.warning,
                    icon: Icons.directions_walk_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int pendingCount, UserModel? currentUser) {
    final wardenName = (currentUser != null && currentUser.name.isNotEmpty)
        ? currentUser.name
        : 'Warden';

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.wardenAccent],
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
                  'Warden Dashboard',
                  style: GoogleFonts.dmSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$wardenName  •  $pendingCount pending',
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

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.wardenAccent
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: selected
                          ? AppTheme.wardenAccent
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.dmSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabToggle(int pendingComplaintsCount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? AppTheme.wardenAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Approvals',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5.sp,
                        color: _activeTab == 0 ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? const Color(0xFFD97706) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Complaints',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5.sp,
                          color: _activeTab == 1 ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      if (pendingComplaintsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingComplaintsCount',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 2 ? const Color(0xFF0284C7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 13,
                          color: _activeTab == 2 ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Attendance',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5.sp,
                            color: _activeTab == 2 ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsTab(List<ComplaintModel> allComplaints) {
    final currentUser = ref.watch(currentUserProvider);
    final wardenId = currentUser?.id.trim().toLowerCase() ?? '';
    final wardenEmail = currentUser?.email.trim().toLowerCase() ?? '';
    final wardenName = currentUser?.name.trim().toLowerCase() ?? '';

    final wardenComplaints = allComplaints.where((c) {
      if (c.clearedByWarden) return false;
      final assignedId = c.assignedWardenId.trim().toLowerCase();
      final assignedName = c.assignedWardenName.trim().toLowerCase();
      if (assignedId.isEmpty && assignedName.isEmpty) return true;
      return (wardenId.isNotEmpty && (assignedId == wardenId || wardenId.contains(assignedId) || assignedId.contains(wardenId))) ||
          (wardenEmail.isNotEmpty && assignedId == wardenEmail) ||
          (wardenName.isNotEmpty && (assignedName == wardenName || wardenName.contains(assignedName) || assignedName.contains(wardenName)));
    }).toList();

    final filteredComplaints = _complaintFilter == 'All'
        ? wardenComplaints
        : wardenComplaints
            .where((c) => c.status.toLowerCase() == _complaintFilter.toLowerCase().replaceAll(' ', '_'))
            .toList();

    return Column(
      children: [
        // Complaint Filter Chips & Clear Resolved Action Button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _complaintFilters.map((f) {
                      final selected = _complaintFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _complaintFilter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFD97706) : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: selected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.dmSans(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Clear Resolved Only Button
              InkWell(
                onTap: () => _showClearResolvedDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Clear Resolved',
                        style: GoogleFonts.dmSans(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredComplaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No complaints found',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  itemCount: filteredComplaints.length,
                  itemBuilder: (context, i) {
                    final complaint = filteredComplaints[i];
                    return _buildWardenComplaintCard(complaint);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWardenComplaintCard(ComplaintModel complaint) {
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

    IconData catIcon;
    switch (complaint.category) {
      case 'Food':
        catIcon = Icons.restaurant_rounded;
        break;
      case 'Water Facility':
        catIcon = Icons.water_drop_rounded;
        break;
      case 'Room':
        catIcon = Icons.bed_rounded;
        break;
      case 'Abnormal Smell':
        catIcon = Icons.warning_amber_rounded;
        break;
      default:
        catIcon = Icons.build_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2440).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 14, color: AppTheme.wardenAccent),
                    const SizedBox(width: 4),
                    Text(
                      complaint.category,
                      style: GoogleFonts.dmSans(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 18,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.complainantName,
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'ID: ${complaint.complainantId.isNotEmpty ? complaint.complainantId : "Resident"}  •  Role: ${complaint.complainantRole}',
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              complaint.description,
              style: GoogleFonts.dmSans(
                fontSize: 10.sp,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
          if (complaint.wardenRemarks != null && complaint.wardenRemarks!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                'Warden Remarks: ${complaint.wardenRemarks}',
                style: GoogleFonts.dmSans(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (complaint.status != 'in_progress' && complaint.status != 'resolved')
                OutlinedButton(
                  onPressed: () => FirebaseService().updateComplaintStatus(
                    complaint.id,
                    'in_progress',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Mark In Progress', style: GoogleFonts.dmSans(fontSize: 9.sp, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              if (complaint.status != 'resolved')
                ElevatedButton(
                  onPressed: () => _showUpdateComplaintStatusDialog(complaint),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Resolve Complaint ✓', style: GoogleFonts.dmSans(fontSize: 9.sp, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateComplaintStatusDialog(ComplaintModel complaint) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resolve Complaint', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Warden Remarks / Resolution Action:', style: GoogleFonts.dmSans(fontSize: 12.sp)),
            const SizedBox(height: 10),
            TextFormField(
              controller: remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Action taken, repaired, or notified maintenance staff...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseService().updateComplaintStatus(
                complaint.id,
                'resolved',
                remarks: remarksController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Mark Resolved ✓', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearResolvedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Resolved Complaints', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to clear all RESOLVED complaints? Pending and In-Progress complaints will be kept safely.',
          style: GoogleFonts.dmSans(fontSize: 11.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final clearedCount = await FirebaseService().clearAllResolvedComplaints();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleared $clearedCount resolved complaints.'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear Resolved', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWardenDetailBottomSheet(
    BuildContext context,
    Map<String, dynamic> request,
  ) {
    final statusStr = (request['status'] as String? ?? '').toLowerCase();
    final isDeclined = statusStr.startsWith('declined');
    final classMamSigned = request['classMamSigned'] as bool? ?? false;
    final hodSigned = request['hodSigned'] as bool? ?? false;
    final wardenSigned = request['wardenSigned'] as bool? ?? false;
    final canApproveOrDecline = !wardenSigned && !isDeclined && statusStr != 'approved' && statusStr != 'cancelled';

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
                          : (wardenSigned
                              ? AppTheme.wardenAccent.withAlpha(30)
                              : AppTheme.warning.withAlpha(30)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDeclined
                          ? 'DECLINED'
                          : (wardenSigned ? 'APPROVED BY YOU' : 'PENDING WARDEN SIGNATURE'),
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDeclined
                            ? AppTheme.error
                            : (wardenSigned ? AppTheme.wardenAccent : AppTheme.warning),
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
                'Warden Approval Details',
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
                  color: AppTheme.wardenAccent,
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
                      backgroundColor: AppTheme.wardenAccent,
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
              _buildWardenSignatureTile(
                role: 'Class Coordinator (Class Mam)',
                name: request['assignedCcName'] as String? ?? 'Pradeepa Mam',
                isSigned: classMamSigned,
              ),
              const SizedBox(height: 6),
              _buildWardenSignatureTile(
                role: 'Head of Department (HOD)',
                name: request['assignedHodName'] as String? ?? 'Kavitha Mam',
                isSigned: hodSigned,
              ),
              const SizedBox(height: 6),
              _buildWardenSignatureTile(
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
                          _showDeclineDialog(reqId);
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
                          backgroundColor: AppTheme.wardenAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approve(reqId);
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Approve Request',
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

  Widget _buildWardenSignatureTile({
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: AppTheme.textSecondary.withAlpha(77),
          ),
          SizedBox(height: 1.h),
          Text(
            'No $_filter requests',
            style: GoogleFonts.dmSans(
              fontSize: 14.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isLeaveActiveInTimeframe(LeaveRequestModel req, String timeframe) {
    final status = req.status.toLowerCase();
    final isApproved = status == 'approved' || req.wardenSigned;
    if (!isApproved) return false;

    final now = DateTime.now();
    final reqDate = DateTime.fromMillisecondsSinceEpoch(req.createdAt);

    if (timeframe == 'Day') {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (req.fromDate.contains(todayStr) || req.toDate.contains(todayStr) || req.submittedOn.contains(todayStr)) {
        return true;
      }
      final diffHours = now.difference(reqDate).inHours;
      return diffHours < 24;
    } else if (timeframe == 'Week') {
      final diffDays = now.difference(reqDate).inDays;
      return diffDays <= 7;
    } else if (timeframe == 'Month') {
      final diffDays = now.difference(reqDate).inDays;
      return diffDays <= 30;
    }
    return true;
  }

  Future<void> _exportAttendanceCsv({
    required List<StudentModel> allStudents,
    required List<LeaveRequestModel> allRequests,
    required String timeframe,
  }) async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final List<List<dynamic>> csvRows = [];
      
      csvRows.add(['SEC HOSTEL - STUDENT ATTENDANCE & MONITORING REPORT']);
      csvRows.add(['Report Date:', dateStr, 'Timeframe Scope:', timeframe.toUpperCase()]);
      csvRows.add([]);
      
      csvRows.add([
        'S.No',
        'Student Name',
        'Roll No / ERP',
        'Department',
        'Year Batch',
        'Hostel Block',
        'Room No',
        'Attendance Status ($timeframe)',
        'Leave Type',
        'Leave Dates (From - To)',
        'Leave Reason',
        'Assigned CC',
        'Assigned HOD',
        'Assigned Warden',
        'Approval Status',
      ]);

      int index = 1;
      int presentCount = 0;
      int absentCount = 0;

      for (final student in allStudents) {
        final studentLeaves = allRequests.where((r) {
          final isMatch = (r.rollNo.isNotEmpty && r.rollNo.toLowerCase() == student.rollNo.toLowerCase()) ||
              (r.studentName.isNotEmpty && r.studentName.toLowerCase() == student.name.toLowerCase());
          if (!isMatch) return false;
          return _isLeaveActiveInTimeframe(r, timeframe);
        }).toList();

        final isAbsent = studentLeaves.isNotEmpty;
        final activeLeave = isAbsent ? studentLeaves.first : null;

        if (isAbsent) {
          absentCount++;
        } else {
          presentCount++;
        }

        csvRows.add([
          index++,
          student.name.isNotEmpty ? student.name : 'Student',
          student.rollNo.isNotEmpty ? student.rollNo : 'N/A',
          student.department.isNotEmpty ? student.department : 'Computer Science',
          student.year.isNotEmpty ? student.year : '3rd Year',
          student.hostelBlock.isNotEmpty ? student.hostelBlock : 'Block A',
          student.roomNo.isNotEmpty ? student.roomNo : '101',
          isAbsent ? 'ABSENT (On Leave)' : 'PRESENT (In Hostel)',
          isAbsent ? (activeLeave?.type ?? 'Home Visit') : '-',
          isAbsent ? '${activeLeave?.fromDate ?? ''} to ${activeLeave?.toDate ?? ''}' : '-',
          isAbsent ? (activeLeave?.reason ?? '-') : '-',
          student.assignedCcName.isNotEmpty ? student.assignedCcName : (activeLeave?.assignedCcName ?? 'CC'),
          student.assignedHodName.isNotEmpty ? student.assignedHodName : (activeLeave?.assignedHodName ?? 'HOD'),
          student.assignedWardenName.isNotEmpty ? student.assignedWardenName : (activeLeave?.assignedWardenName ?? 'Warden'),
          isAbsent ? (activeLeave?.status ?? 'approved') : 'Active In Hostel',
        ]);
      }

      csvRows.add([]);
      csvRows.add(['ATTENDANCE METRICS SUMMARY']);
      csvRows.add(['Total Enrolled Students:', allStudents.length]);
      csvRows.add(['Present in Hostel:', presentCount]);
      csvRows.add(['Absent (On Leave):', absentCount]);
      final occupancyRate = allStudents.isNotEmpty ? ((presentCount / allStudents.length) * 100).toStringAsFixed(1) : '100';
      csvRows.add(['Hostel Occupancy Rate:', '$occupancyRate%']);

      final String csvData = const ListToCsvConverter().convert(csvRows);
      
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/Sec_Hostel_Attendance_${timeframe}_$dateStr.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);

      if (mounted) {
        final mediaSize = MediaQuery.of(context).size;
        final origin = Rect.fromLTWH(
          mediaSize.width * 0.1,
          mediaSize.height * 0.3,
          mediaSize.width * 0.8,
          mediaSize.height * 0.3,
        );

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Sec Hostel Attendance Report ($timeframe) - $dateStr',
          subject: 'Sec Hostel Attendance Report ($timeframe)',
          sharePositionOrigin: origin,
        );
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel/CSV report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildAttendanceTab({
    required List<UserModel> studentUsers,
    required List<StudentModel> allStudents,
    required List<LeaveRequestModel> allRequests,
  }) {
    final List<StudentModel> effectiveStudents = allStudents.isNotEmpty
        ? allStudents
        : (studentUsers.isNotEmpty
            ? studentUsers
                .map((u) => StudentModel(
                      docId: u.docId,
                      id: u.erpNo.isNotEmpty ? u.erpNo : (u.id.isNotEmpty ? u.id : 'STU001'),
                      name: u.name,
                      email: u.email,
                      department: u.department.isNotEmpty ? u.department : 'Computer Science',
                      year: u.year.isNotEmpty ? u.year : '3rd Year',
                      roomNo: '101',
                      hostelBlock: 'Block A',
                    ))
                .toList()
            : [
                StudentModel(
                  docId: 'stu_1',
                  id: 'CS2021045',
                  name: 'Rahul Sharma',
                  email: 'rahul@sec.edu',
                  department: 'Computer Science',
                  year: '3rd Year',
                  roomNo: '204',
                  hostelBlock: 'Block A',
                  assignedWardenName: 'Siva Sir',
                ),
                StudentModel(
                  docId: 'stu_2',
                  id: 'IT2021012',
                  name: 'Priya Ram',
                  email: 'priya@sec.edu',
                  department: 'Information Tech',
                  year: '2nd Year',
                  roomNo: '108',
                  hostelBlock: 'Block B',
                  assignedWardenName: 'Siva Sir',
                ),
                StudentModel(
                  docId: 'stu_3',
                  id: 'ECE2021089',
                  name: 'Karthik Raja',
                  email: 'karthik@sec.edu',
                  department: 'ECE',
                  year: '4th Year',
                  roomNo: '312',
                  hostelBlock: 'Block A',
                  assignedWardenName: 'Siva Sir',
                ),
              ]);

    final List<Map<String, dynamic>> studentAttendanceStatus = [];
    int absentCount = 0;
    int presentCount = 0;

    for (final student in effectiveStudents) {
      final studentLeaves = allRequests.where((r) {
        final isMatch = (r.rollNo.isNotEmpty && r.rollNo.toLowerCase() == student.rollNo.toLowerCase()) ||
            (r.studentName.isNotEmpty && r.studentName.toLowerCase() == student.name.toLowerCase());
        if (!isMatch) return false;
        return _isLeaveActiveInTimeframe(r, _attendanceTimeframe);
      }).toList();

      final isAbsent = studentLeaves.isNotEmpty;
      final activeLeave = isAbsent ? studentLeaves.first : null;

      if (isAbsent) {
        absentCount++;
      } else {
        presentCount++;
      }

      studentAttendanceStatus.add({
        'student': student,
        'isAbsent': isAbsent,
        'activeLeave': activeLeave,
      });
    }

    final query = _attendanceSearchQuery.trim().toLowerCase();
    final filteredStatus = studentAttendanceStatus.where((item) {
      final StudentModel s = item['student'];
      final isAbsent = item['isAbsent'] as bool;

      if (_attendanceStatusFilter == 'Present' && isAbsent) return false;
      if (_attendanceStatusFilter == 'Absent' && !isAbsent) return false;

      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.rollNo.toLowerCase().contains(query) ||
          s.roomNo.toLowerCase().contains(query) ||
          s.department.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Day', 'Week', 'Month'].map((t) {
                      final isSelected = _attendanceTimeframe == t;
                      return GestureDetector(
                        onTap: () => setState(() => _attendanceTimeframe = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t == 'Day' ? 'Today' : (t == 'Week' ? 'Week' : 'Month'),
                            style: GoogleFonts.dmSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: _isExporting
                    ? null
                    : () => _exportAttendanceCsv(
                          allStudents: effectiveStudents,
                          allRequests: allRequests,
                          timeframe: _attendanceTimeframe,
                        ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.table_chart_rounded, size: 15, color: Colors.white),
                label: Text(
                  _isExporting ? '...' : 'Export Excel',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 9.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1C42), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceMetric('Total Enrolled', effectiveStudents.length.toString(), Colors.white, Icons.groups_rounded),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildAttendanceMetric('Present ($presentCount)', '${effectiveStudents.isNotEmpty ? ((presentCount / effectiveStudents.length) * 100).toStringAsFixed(0) : 100}%', const Color(0xFF34D399), Icons.check_circle_rounded),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildAttendanceMetric('Absent ($absentCount)', '${effectiveStudents.isNotEmpty ? ((absentCount / effectiveStudents.length) * 100).toStringAsFixed(0) : 0}%', const Color(0xFFF87171), Icons.person_off_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              TextField(
                controller: _attendanceSearchController,
                onChanged: (val) => setState(() => _attendanceSearchQuery = val),
                style: GoogleFonts.dmSans(fontSize: 11.sp),
                decoration: InputDecoration(
                  hintText: 'Search student name, roll no, room...',
                  hintStyle: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                  suffixIcon: _attendanceSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _attendanceSearchController.clear();
                            setState(() => _attendanceSearchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['All', 'Present', 'Absent'].map((st) {
                  final isSel = _attendanceStatusFilter == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        st == 'All' ? 'All (${effectiveStudents.length})' : (st == 'Present' ? 'Present ($presentCount)' : 'Absent ($absentCount)'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: st == 'Present' ? const Color(0xFF10B981) : (st == 'Absent' ? const Color(0xFFEF4444) : const Color(0xFF0284C7)),
                      backgroundColor: AppTheme.surfaceLight,
                      onSelected: (_) => setState(() => _attendanceStatusFilter = st),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredStatus.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search_rounded, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No student records matching filter',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                  itemCount: filteredStatus.length,
                  itemBuilder: (ctx, idx) {
                    final item = filteredStatus[idx];
                    final StudentModel student = item['student'];
                    final bool isAbsent = item['isAbsent'];
                    final LeaveRequestModel? activeLeave = item['activeLeave'];

                    return _AttendanceStudentCard(
                      student: student,
                      isAbsent: isAbsent,
                      activeLeave: activeLeave,
                      timeframe: _attendanceTimeframe,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceMetric(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 8.5.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WardenLeaveCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onTapCard;

  const _WardenLeaveCard({
    required this.request,
    required this.onApprove,
    required this.onDecline,
    required this.onTapCard,
  });

  Color get _statusColor {
    final s = (request['status'] as String? ?? '').toLowerCase();
    if (s == 'approved') return AppTheme.wardenAccent;
    if (s.startsWith('declined') || s == 'cancelled') return AppTheme.error;
    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    final statusStr = (request['status'] as String? ?? '').toLowerCase();
    final isWardenSigned = request['wardenSigned'] as bool? ?? false;
    final isPending = !isWardenSigned && !statusStr.startsWith('declined') && statusStr != 'approved' && statusStr != 'cancelled';
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
                  color: AppTheme.studentAccent.withAlpha(26),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.studentAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['studentName'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      request['rollNo'] as String,
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
                  color: _statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  (request['status'] as String).toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: request['type'] as String,
                icon: Icons.category_rounded,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: '${request['fromDate']} → ${request['toDate']}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          if (request['departureTime'] != null || request['arrivalTime'] != null) ...[
            const SizedBox(height: 6),
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
              color: AppTheme.wardenAccent.withAlpha(18),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppTheme.wardenAccent.withAlpha(77),
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
                      color: AppTheme.wardenAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reason for Leave:',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.wardenAccent,
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Declined: ${request['declineReason']}',
                style: GoogleFonts.dmSans(
                  fontSize: 10.sp,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildSignatureRow(),
          if (isPending) ...[
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
                        fontSize: 12.sp,
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
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wardenAccent,
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

  Widget _buildSignatureRow() {
    final sigs = [
      {'label': 'Class Mam', 'signed': request['classMamSigned'] as bool},
      {'label': 'HOD', 'signed': request['hodSigned'] as bool},
      {'label': 'Warden', 'signed': request['wardenSigned'] as bool},
    ];
    return Row(
      children: sigs.map((s) {
        final signed = s['signed'] as bool;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
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
                  s['label'] as String,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10.sp,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _OccupancyStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AttendanceStudentCard extends StatelessWidget {
  final StudentModel student;
  final bool isAbsent;
  final LeaveRequestModel? activeLeave;
  final String timeframe;

  const _AttendanceStudentCard({
    required this.student,
    required this.isAbsent,
    this.activeLeave,
    required this.timeframe,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAbsent ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAbsent ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withAlpha(25),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name.isNotEmpty ? student.name : 'Student',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAbsent ? Icons.directions_walk_rounded : Icons.check_circle_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAbsent ? 'ABSENT' : 'PRESENT',
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll: ${student.rollNo.isNotEmpty ? student.rollNo : 'N/A'} • ${student.department.isNotEmpty ? student.department : 'CS'} (${student.year})',
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Room ${student.roomNo.isNotEmpty ? student.roomNo : '101'}, ${student.hostelBlock.isNotEmpty ? student.hostelBlock : 'Block A'}',
                style: GoogleFonts.dmSans(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isAbsent && activeLeave != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeLeave!.type,
                    style: GoogleFonts.dmSans(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isAbsent && activeLeave != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 13, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Leave Dates: ${activeLeave!.fromDate} to ${activeLeave!.toDate}',
                        style: GoogleFonts.dmSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  if (activeLeave!.reason.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Reason: "${activeLeave!.reason}"',
                      style: GoogleFonts.dmSans(
                        fontSize: 8.5.sp,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF7F1D1D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
