import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/leave_request_model.dart';
import '../../models/student_model.dart';
import '../../models/warden_model.dart';
import '../../models/hod_model.dart';
import '../../models/cc_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../widgets/notification_bell_widget.dart';
import '../profile_screen/profile_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'All Requests',
    'Students',
    'CCs',
    'HODs',
    'Wardens',
    'Reports'
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return StreamBuilder<List<LeaveRequestModel>>(
      stream: FirebaseService().leaveRequestsStream,
      initialData: FirebaseService().currentLeaveRequests,
      builder: (context, requestsSnapshot) {
        final allRequests = requestsSnapshot.data ?? [];
        final totalRequests = allRequests.length;
        final approvedCount =
            allRequests.where((r) => r.status.toLowerCase() == 'approved').length;
        final pendingCount =
            allRequests.where((r) => r.status.toLowerCase() == 'pending').length;
        final declinedCount =
            allRequests.where((r) => r.status.toLowerCase() == 'declined').length;

        return StreamBuilder<List<UserModel>>(
          stream: FirebaseService().usersStream,
          initialData: FirebaseService().currentUsers,
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? [];

            return StreamBuilder<List<StudentModel>>(
              stream: FirebaseService().studentsStream,
              initialData: FirebaseService().currentStudents,
              builder: (context, studentsSnapshot) {
                final students = studentsSnapshot.data ?? [];

                return StreamBuilder<List<WardenModel>>(
                  stream: FirebaseService().wardensStream,
                  initialData: FirebaseService().currentWardens,
                  builder: (context, wardensSnapshot) {
                    final wardens = wardensSnapshot.data ?? [];

                    return StreamBuilder<List<HodModel>>(
                      stream: FirebaseService().hodsStream,
                      initialData: FirebaseService().currentHods,
                      builder: (context, hodsSnapshot) {
                        final hods = hodsSnapshot.data ?? [];

                        return StreamBuilder<List<CcModel>>(
                          stream: FirebaseService().ccsStream,
                          initialData: FirebaseService().currentCcs,
                          builder: (context, ccsSnapshot) {
                            final ccs = ccsSnapshot.data ?? [];

                            return Scaffold(
                              backgroundColor: AppTheme.backgroundLight,
                              floatingActionButton: _buildFab(
                                context,
                                wardens: wardens,
                                hods: hods,
                                ccs: ccs,
                              ),
                              body: SafeArea(
                                child: Column(
                                  children: [
                                    _buildHeader(context, currentUser),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 1.5.h,
                                      ),
                                      child: Row(
                                        children: [
                                          _AdminStat(
                                            label: 'Total',
                                            value: totalRequests.toString(),
                                            color: AppTheme.adminAccent,
                                          ),
                                          SizedBox(width: 2.w),
                                          _AdminStat(
                                            label: 'Approved',
                                            value: approvedCount.toString(),
                                            color: AppTheme.wardenAccent,
                                          ),
                                          SizedBox(width: 2.w),
                                          _AdminStat(
                                            label: 'Pending',
                                            value: pendingCount.toString(),
                                            color: AppTheme.warning,
                                          ),
                                          SizedBox(width: 2.w),
                                          _AdminStat(
                                            label: 'Declined',
                                            value: declinedCount.toString(),
                                            color: AppTheme.error,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildTabs(),
                                    Expanded(
                                      child: _buildTabContent(
                                        allRequests: allRequests,
                                        users: users,
                                        students: students,
                                        wardens: wardens,
                                        hods: hods,
                                        ccs: ccs,
                                      ),
                                    ),
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
          },
        );
      },
    );
  }

  Widget? _buildFab(
    BuildContext context, {
    required List<WardenModel> wardens,
    required List<HodModel> hods,
    required List<CcModel> ccs,
  }) {
    switch (_selectedTab) {
      case 1: // Students
        return FloatingActionButton.extended(
          onPressed: () => _showStudentFormDialog(context, wardens: wardens, hods: hods, ccs: ccs),
          backgroundColor: AppTheme.studentAccent,
          icon: const Icon(Icons.school_rounded, color: Colors.white),
          label: Text('Add Student', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
        );
      case 2: // CCs
        return FloatingActionButton.extended(
          onPressed: () => _showCcFormDialog(context),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.badge_rounded, color: Colors.white),
          label: Text('Add CC / Class Mam', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
        );
      case 3: // HODs
        return FloatingActionButton.extended(
          onPressed: () => _showHodFormDialog(context),
          backgroundColor: AppTheme.hodAccent,
          icon: const Icon(Icons.supervisor_account_rounded, color: Colors.white),
          label: Text('Add HOD', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
        );
      case 4: // Wardens
        return FloatingActionButton.extended(
          onPressed: () => _showWardenFormDialog(context),
          backgroundColor: AppTheme.wardenAccent,
          icon: const Icon(Icons.shield_rounded, color: Colors.white),
          label: Text('Add Warden', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
        );
      default:
        return null;
    }
  }

  Widget _buildHeader(BuildContext context, UserModel? currentUser) {
    final adminName = (currentUser != null && currentUser.name.isNotEmpty)
        ? currentUser.name
        : 'System Admin';

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.adminAccent],
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
                  'Admin Dashboard',
                  style: GoogleFonts.dmSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$adminName  •  Firestore Control',
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

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Container(
        padding: const EdgeInsets.all(4),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.adminAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _tabs[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required List<LeaveRequestModel> allRequests,
    required List<UserModel> users,
    required List<StudentModel> students,
    required List<WardenModel> wardens,
    required List<HodModel> hods,
    required List<CcModel> ccs,
  }) {
    switch (_selectedTab) {
      case 0:
        return _buildAllRequests(allRequests);
      case 1:
        return _buildStudentsTab(students: students, wardens: wardens, hods: hods, ccs: ccs);
      case 2:
        return _buildCcsTab(ccs);
      case 3:
        return _buildHodsTab(hods);
      case 4:
        return _buildWardensTab(wardens);
      case 5:
        return _buildReports(allRequests, users, students, wardens, hods, ccs);
      default:
        return _buildReports(allRequests, users, students, wardens, hods, ccs);
    }
  }

  Widget _buildAllRequests(List<LeaveRequestModel> allRequests) {
    if (allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(128)),
            const SizedBox(height: 12),
            Text(
              'No leave requests found in history.',
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Logs (${allRequests.length})',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _confirmClearAllRequestHistory(context, allRequests.length),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: Text(
                  'Clear History',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: allRequests.length,
            itemBuilder: (_, i) {
              final req = allRequests[i];
              final statusColor = req.status.toLowerCase() == 'approved'
                  ? AppTheme.wardenAccent
                  : req.status.toLowerCase() == 'declined'
                      ? AppTheme.error
                      : AppTheme.warning;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.5.h),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.adminAccent.withAlpha(26),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.adminAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.studentName,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${req.rollNo}  •  ${req.type}  •  ${req.fromDate}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10.sp,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          req.status.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                        onPressed: () => _confirmDeleteSingleRequest(context, req),
                        tooltip: 'Delete History Entry',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 1. STUDENTS TAB
  Widget _buildStudentsTab({
    required List<StudentModel> students,
    required List<WardenModel> wardens,
    required List<HodModel> hods,
    required List<CcModel> ccs,
  }) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students in "students" collection.',
          style: GoogleFonts.dmSans(fontSize: 12.sp, color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final student = students[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.2.h),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
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
                      child: const Icon(Icons.school_rounded, color: AppTheme.studentAccent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'ERP no: ${student.id}  •  Dept: ${student.department}  •  ${student.hostelBlock}',
                            style: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.adminAccent, size: 20),
                      onPressed: () => _showStudentFormDialog(context, existingStudent: student, wardens: wardens, hods: hods, ccs: ccs),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                      onPressed: () async {
                        await FirebaseService().deleteStudent(student.docId);
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAssignedChip('Warden', student.assignedWardenName.isNotEmpty ? student.assignedWardenName : 'Unassigned', AppTheme.wardenAccent),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildAssignedChip('CC', student.assignedCcName.isNotEmpty ? student.assignedCcName : 'Unassigned', AppTheme.primary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildAssignedChip('HOD', student.assignedHodName.isNotEmpty ? student.assignedHodName : 'Unassigned', AppTheme.hodAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignedChip(String role, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: GoogleFonts.dmSans(fontSize: 8.sp, fontWeight: FontWeight.w700, color: color)),
          Text(name, style: GoogleFonts.dmSans(fontSize: 9.sp, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // 2. WARDENS TAB (Master Collection)
  Widget _buildWardensTab(List<WardenModel> wardens) {
    if (wardens.isEmpty) {
      return Center(
        child: Text('No wardens in "wardens" collection.', style: GoogleFonts.dmSans(fontSize: 12.sp, color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: wardens.length,
      itemBuilder: (_, i) {
        final warden = wardens[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.wardenAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppTheme.wardenAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(warden.name, style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Text('ID: ${warden.id}  •  ${warden.hostelBlock}  •  ${warden.email}', style: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.textSecondary)),
                      if (warden.phone.isNotEmpty) Text(warden.phone, style: GoogleFonts.dmSans(fontSize: 9.sp, color: AppTheme.textSecondary.withAlpha(204))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.adminAccent, size: 20),
                  onPressed: () => _showWardenFormDialog(context, existingWarden: warden),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                  onPressed: () async => await FirebaseService().deleteWarden(warden.docId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. HODS TAB (Master Collection)
  Widget _buildHodsTab(List<HodModel> hods) {
    if (hods.isEmpty) {
      return Center(
        child: Text('No HODs in "hods" collection.', style: GoogleFonts.dmSans(fontSize: 12.sp, color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: hods.length,
      itemBuilder: (_, i) {
        final hod = hods[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.hodAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.supervisor_account_rounded, color: AppTheme.hodAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hod.name, style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Text('ID: ${hod.id}  •  Dept: ${hod.department}  •  ${hod.email}', style: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.textSecondary)),
                      if (hod.phone.isNotEmpty) Text(hod.phone, style: GoogleFonts.dmSans(fontSize: 9.sp, color: AppTheme.textSecondary.withAlpha(204))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.adminAccent, size: 20),
                  onPressed: () => _showHodFormDialog(context, existingHod: hod),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                  onPressed: () async => await FirebaseService().deleteHod(hod.docId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. CCS TAB (Master Collection)
  Widget _buildCcsTab(List<CcModel> ccs) {
    if (ccs.isEmpty) {
      return Center(
        child: Text('No Class Coordinators in "ccs" collection.', style: GoogleFonts.dmSans(fontSize: 12.sp, color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: ccs.length,
      itemBuilder: (_, i) {
        final cc = ccs[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.badge_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cc.name, style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Text('ID: ${cc.id}  •  Section: ${cc.section}  •  ${cc.yearBatch}', style: GoogleFonts.dmSans(fontSize: 10.sp, color: AppTheme.textSecondary)),
                      if (cc.email.isNotEmpty) Text(cc.email, style: GoogleFonts.dmSans(fontSize: 9.sp, color: AppTheme.textSecondary.withAlpha(204))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.adminAccent, size: 20),
                  onPressed: () => _showCcFormDialog(context, existingCc: cc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                  onPressed: () async => await FirebaseService().deleteCc(cc.docId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. USERS TAB REMOVED (Master collections now managed directly in Students, Wardens, HODs & CCs tabs)

  // 6. REPORTS TAB
  Widget _buildReports(
    List<LeaveRequestModel> allRequests,
    List<UserModel> users,
    List<StudentModel> students,
    List<WardenModel> wardens,
    List<HodModel> hods,
    List<CcModel> ccs,
  ) {
    final totalReq = allRequests.length;
    final approvedReq =
        allRequests.where((r) => r.status.toLowerCase() == 'approved').length;
    final approvalRate =
        totalReq == 0 ? '0%' : '${((approvedReq / totalReq) * 100).round()}%';

    final stats = [
      {
        'label': 'Total Requests (Rate)',
        'value': '$totalReq ($approvalRate Approved)',
        'icon': Icons.assignment_rounded,
        'color': AppTheme.adminAccent,
      },
      {
        'label': 'Students Collection',
        'value': students.length.toString(),
        'icon': Icons.school_rounded,
        'color': AppTheme.studentAccent,
      },
      {
        'label': 'Wardens Collection',
        'value': wardens.length.toString(),
        'icon': Icons.shield_rounded,
        'color': AppTheme.wardenAccent,
      },
      {
        'label': 'HODs & CCs Collections',
        'value': '${hods.length + ccs.length}',
        'icon': Icons.badge_rounded,
        'color': AppTheme.hodAccent,
      },
    ];
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      children: [
        ...stats.map((s) {
          return Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['label'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          s['value'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: s['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            final jsonDump = await FirebaseService().exportDatabaseToJsonDump();
            if (mounted) {
              _showJsonDumpViewer(context, jsonDump);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          icon: const Icon(Icons.data_object_rounded, color: Colors.white),
          label: Text(
            'Export Database (JSON Dump)',
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _confirmClearAllRequestHistory(context, totalReq),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
          label: Text(
            'Clear All Request History',
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showJsonDumpViewer(BuildContext context, String jsonDump) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 85.h,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.data_object_rounded, color: AppTheme.adminAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Firestore Database JSON Dump',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonDump));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'JSON Dump copied to clipboard!',
                              style: GoogleFonts.dmSans(),
                            ),
                            backgroundColor: AppTheme.wardenAccent,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Copy JSON',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final filePath = await FirebaseService().saveJsonDumpToLocalFile(jsonDump);
                          if (ctx.mounted) {
                            showDialog(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: Row(
                                  children: [
                                    const Icon(Icons.save_rounded, color: AppTheme.wardenAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'File Saved Locally',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                content: SelectableText(
                                  'Database JSON Dump successfully saved to:\n\n$filePath',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10.sp,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: Text(
                                      'OK',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error saving file: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.wardenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: const Icon(Icons.save_alt_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Save Local File',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonDump,
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5.sp,
                        color: const Color(0xFF38BDF8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // DIALOG FOR STUDENT CREATION WITH WARDEN, CC & HOD ASSIGNMENT
  void _showStudentFormDialog(
    BuildContext context, {
    StudentModel? existingStudent,
    required List<WardenModel> wardens,
    required List<HodModel> hods,
    required List<CcModel> ccs,
  }) {
    final isEditing = existingStudent != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingStudent.name : '');
    final erpNoCtrl = TextEditingController(text: isEditing ? existingStudent.id : '');
    final emailCtrl = TextEditingController(text: isEditing ? existingStudent.email : '');
    final roomNoCtrl = TextEditingController(text: isEditing ? existingStudent.roomNo : '101');
    final passwordCtrl = TextEditingController(text: isEditing ? existingStudent.password : 'student123');
    final deptCtrl = TextEditingController(text: isEditing ? existingStudent.department : 'Computer Science');
    String selectedYear = isEditing ? (existingStudent.yearBatch.isNotEmpty ? existingStudent.yearBatch : '3rd Year') : '3rd Year';
    String selectedHostelBlock = isEditing ? (existingStudent.hostelBlock.isNotEmpty ? existingStudent.hostelBlock : 'Engineering') : 'Engineering';

    WardenModel? selectedWarden = wardens.isNotEmpty
        ? wardens.firstWhere((w) => w.name == existingStudent?.assignedWardenName || w.id == existingStudent?.assignedWardenId, orElse: () => wardens.first)
        : null;
    HodModel? selectedHod = hods.isNotEmpty
        ? hods.firstWhere((h) => h.name == existingStudent?.assignedHodName || h.id == existingStudent?.assignedHodId, orElse: () => hods.first)
        : null;
    CcModel? selectedCc = ccs.isNotEmpty
        ? ccs.firstWhere((c) => c.name == existingStudent?.assignedCcName || c.id == existingStudent?.assignedCcId, orElse: () => ccs.first)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Student Record' : 'Add New Student',
                              style: GoogleFonts.dmSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outline_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: erpNoCtrl,
                              decoration: InputDecoration(
                                labelText: 'ERP no',
                                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                                  .map((y) => DropdownMenuItem(value: y, child: Text(y, style: GoogleFonts.dmSans(), overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: deptCtrl,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                prefixIcon: const Icon(Icons.school_outlined, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: emailCtrl,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: roomNoCtrl,
                              decoration: InputDecoration(
                                labelText: 'Room No',
                                prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: ['Engineering', 'Arts'].contains(selectedHostelBlock) ? selectedHostelBlock : 'Engineering',
                              decoration: InputDecoration(
                                labelText: 'Hostel Block',
                                prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ['Engineering', 'Arts']
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.dmSans(), overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedHostelBlock = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Password (For Login)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // WARDEN DROPDOWN
                      DropdownButtonFormField<WardenModel>(
                        isExpanded: true,
                        initialValue: selectedWarden,
                        decoration: InputDecoration(
                          labelText: 'Assigned Warden',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: wardens.map((w) => DropdownMenuItem(value: w, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setModalState(() => selectedWarden = val),
                      ),
                      const SizedBox(height: 12),
                      // CC / CLASS MAM DROPDOWN
                      DropdownButtonFormField<CcModel>(
                        isExpanded: true,
                        initialValue: selectedCc,
                        decoration: InputDecoration(
                          labelText: 'Assigned Class Coordinator (CC)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ccs.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.section})', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setModalState(() => selectedCc = val),
                      ),
                      const SizedBox(height: 12),
                      // HOD DROPDOWN
                      DropdownButtonFormField<HodModel>(
                        isExpanded: true,
                        initialValue: selectedHod,
                        decoration: InputDecoration(
                          labelText: 'Assigned HOD',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: hods.map((h) => DropdownMenuItem(value: h, child: Text('${h.name} (${h.department})', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setModalState(() => selectedHod = val),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.studentAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final erpNo = erpNoCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            if (name.isEmpty || erpNo.isEmpty) return;

                            final student = StudentModel(
                              docId: isEditing ? existingStudent.docId : FirebaseService().generateUniqueDocId(name),
                              id: erpNo,
                              name: name,
                              email: email.isNotEmpty ? email : 'student@hostel.edu',
                              password: passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : 'student123',
                              department: deptCtrl.text.trim(),
                              year: selectedYear,
                              hostelBlock: selectedHostelBlock,
                              roomNo: roomNoCtrl.text.trim(),
                              assignedWardenId: selectedWarden?.id ?? '',
                              assignedWardenName: selectedWarden?.name ?? '',
                              assignedCcId: selectedCc?.id ?? '',
                              assignedCcName: selectedCc?.name ?? '',
                              assignedHodId: selectedHod?.id ?? '',
                              assignedHodName: selectedHod?.name ?? '',
                            );

                            if (isEditing) {
                              await FirebaseService().updateStudent(student);
                            } else {
                              await FirebaseService().addStudent(student);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Student Record',
                            style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // DIALOG FOR WARDEN MASTER ENTRY
  void _showWardenFormDialog(BuildContext context, {WardenModel? existingWarden}) {
    final isEditing = existingWarden != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingWarden.name : '');
    final blockCtrl = TextEditingController(text: isEditing ? existingWarden.hostelBlock : 'A-Block');
    final emailCtrl = TextEditingController(text: isEditing ? existingWarden.email : '');
    final pwdCtrl = TextEditingController(text: isEditing ? existingWarden.password : 'warden123');
    final phoneCtrl = TextEditingController(text: isEditing ? existingWarden.phone : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Warden Record' : 'Add Warden Record',
                          style: GoogleFonts.dmSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Warden Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: blockCtrl, decoration: InputDecoration(labelText: 'Hostel Block', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: pwdCtrl, decoration: InputDecoration(labelText: 'Password (For Login)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wardenAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final docId = isEditing
                            ? existingWarden.docId
                            : FirebaseService().generateUniqueDocId(nameCtrl.text.trim());
                        final warden = WardenModel(
                          docId: docId,
                          id: docId,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : 'warden123',
                          phone: phoneCtrl.text.trim(),
                          hostelBlock: blockCtrl.text.trim(),
                        );
                        if (isEditing) {
                          await FirebaseService().updateWarden(warden);
                        } else {
                          await FirebaseService().addWarden(warden);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(isEditing ? 'Save Warden' : 'Create Warden Record', style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // DIALOG FOR HOD MASTER ENTRY
  void _showHodFormDialog(BuildContext context, {HodModel? existingHod}) {
    final isEditing = existingHod != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingHod.name : '');
    final emailCtrl = TextEditingController(text: isEditing ? existingHod.email : '');
    final pwdCtrl = TextEditingController(text: isEditing ? existingHod.password : 'hod123');
    final phoneCtrl = TextEditingController(text: isEditing ? existingHod.phone : '');
    final deptCtrl = TextEditingController(text: isEditing ? existingHod.department : 'CSE');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit HOD Record' : 'Add HOD Record',
                          style: GoogleFonts.dmSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'HOD Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: deptCtrl, decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: pwdCtrl, decoration: InputDecoration(labelText: 'Password (For Login)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hodAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final docId = isEditing
                            ? existingHod.docId
                            : FirebaseService().generateUniqueDocId(nameCtrl.text.trim());
                        final hod = HodModel(
                          docId: docId,
                          id: docId,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : 'hod123',
                          phone: phoneCtrl.text.trim(),
                          department: deptCtrl.text.trim(),
                        );
                        if (isEditing) {
                          await FirebaseService().updateHod(hod);
                        } else {
                          await FirebaseService().addHod(hod);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(isEditing ? 'Save HOD' : 'Create HOD Record', style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // DIALOG FOR CC MASTER ENTRY
  void _showCcFormDialog(BuildContext context, {CcModel? existingCc}) {
    final isEditing = existingCc != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingCc.name : '');
    final emailCtrl = TextEditingController(text: isEditing ? existingCc.email : '');
    final pwdCtrl = TextEditingController(text: isEditing ? existingCc.password : 'cc123');
    final phoneCtrl = TextEditingController(text: isEditing ? existingCc.phone : '');
    final sectionCtrl = TextEditingController(text: isEditing ? existingCc.section : 'Section A');
    String selectedYear = isEditing
        ? (['1st Year', '2nd Year', '3rd Year', '4th Year'].contains(existingCc.yearBatch)
            ? existingCc.yearBatch
            : '3rd Year')
        : '3rd Year';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit CC Record' : 'Add CC / Class Mam Record',
                              style: GoogleFonts.dmSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'CC / Class Mam Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(controller: sectionCtrl, decoration: InputDecoration(labelText: 'Section (e.g. Section A)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year / Batch',
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                                  .map((y) => DropdownMenuItem(value: y, child: Text(y, style: GoogleFonts.dmSans())))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: pwdCtrl, decoration: InputDecoration(labelText: 'Password (For Login)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            final docId = isEditing
                                ? existingCc.docId
                                : FirebaseService().generateUniqueDocId(nameCtrl.text.trim());
                            final cc = CcModel(
                              docId: docId,
                              id: docId,
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : 'cc123',
                              phone: phoneCtrl.text.trim(),
                              section: sectionCtrl.text.trim(),
                              yearBatch: selectedYear,
                            );
                            if (isEditing) {
                              await FirebaseService().updateCc(cc);
                            } else {
                              await FirebaseService().addCc(cc);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(isEditing ? 'Save CC' : 'Create CC Record', style: GoogleFonts.dmSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmClearAllRequestHistory(BuildContext context, int count) {
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No leave request history available to clear.', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.textSecondary,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clear Request History',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13.5.sp),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all $count leave request history entries?\n\nThis will permanently wipe all leave records from Firestore and local state. This action cannot be undone.',
          style: GoogleFonts.dmSans(fontSize: 10.5.sp, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text('Clear All ($count)', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService().clearAllLeaveRequests();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All $count leave request history records cleared successfully!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingleRequest(BuildContext context, LeaveRequestModel req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Request Entry',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13.sp),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete leave request history entry for "${req.studentName}" (${req.fromDate})?',
          style: GoogleFonts.dmSans(fontSize: 10.5.sp, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService().deleteLeaveRequest(req.docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted leave request for ${req.studentName}.'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // END OF DASHBOARD WIDGETS
}

class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AdminStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 8.sp,
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
