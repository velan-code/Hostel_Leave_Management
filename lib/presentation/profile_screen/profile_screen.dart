import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../models/student_model.dart';
import '../../models/warden_model.dart';
import '../../models/hod_model.dart';
import '../../models/cc_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/firebase_service.dart';

class ProfileScreen extends ConsumerWidget {
  final StudentModel? studentDetails;

  const ProfileScreen({super.key, this.studentDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final String roleLower = (user?.role ?? '').toLowerCase().trim();

    return StreamBuilder<List<UserModel>>(
      stream: FirebaseService().usersStream,
      initialData: FirebaseService().currentUsers,
      builder: (context, usersSnapshot) {
        final usersList = usersSnapshot.data ?? [];

        // Match updated user model from real-time database cache
        UserModel? updatedUser;
        if (user != null) {
          final uEmail = user.email.trim().toLowerCase();
          final uId = user.id.trim().toLowerCase();
          final uDocId = user.docId.trim().toLowerCase();

          try {
            updatedUser = usersList.firstWhere(
              (u) =>
                  (uEmail.isNotEmpty && u.email.trim().toLowerCase() == uEmail) ||
                  (uId.isNotEmpty && u.erpNo.trim().toLowerCase() == uId) ||
                  (uDocId.isNotEmpty && u.docId.trim().toLowerCase() == uDocId),
            );
          } catch (_) {
            updatedUser = user;
          }
        } else {
          updatedUser = user;
        }

        // Dedicated Role Model Matchers for Warden, HOD, CC, Student
        WardenModel? matchedWarden;
        HodModel? matchedHod;
        CcModel? matchedCc;
        StudentModel? matchedStudent = studentDetails;

        final uEmail = (updatedUser?.email ?? user?.email ?? '').trim().toLowerCase();
        final uId = (updatedUser?.erpNo ?? updatedUser?.id ?? user?.id ?? '').trim().toLowerCase();

        if (roleLower == 'warden') {
          final wardens = FirebaseService().currentWardens;
          try {
            matchedWarden = wardens.firstWhere(
              (w) =>
                  (uEmail.isNotEmpty && w.email.trim().toLowerCase() == uEmail) ||
                  (uId.isNotEmpty && (w.id.trim().toLowerCase() == uId || w.docId.trim().toLowerCase() == uId)),
            );
          } catch (_) {}
        } else if (roleLower == 'hod') {
          final hods = FirebaseService().currentHods;
          try {
            matchedHod = hods.firstWhere(
              (h) =>
                  (uEmail.isNotEmpty && h.email.trim().toLowerCase() == uEmail) ||
                  (uId.isNotEmpty && (h.id.trim().toLowerCase() == uId || h.docId.trim().toLowerCase() == uId)),
            );
          } catch (_) {}
        } else if (roleLower == 'cc' || roleLower == 'class mam' || roleLower == 'class coordinator' || roleLower == 'class counselor') {
          final ccs = FirebaseService().currentCcs;
          try {
            matchedCc = ccs.firstWhere(
              (c) =>
                  (uEmail.isNotEmpty && c.email.trim().toLowerCase() == uEmail) ||
                  (uId.isNotEmpty && (c.id.trim().toLowerCase() == uId || c.docId.trim().toLowerCase() == uId)),
            );
          } catch (_) {}
        } else if (roleLower == 'student' && matchedStudent == null) {
          final students = FirebaseService().currentStudents;
          try {
            matchedStudent = students.firstWhere(
              (s) =>
                  (uEmail.isNotEmpty && s.email.trim().toLowerCase() == uEmail) ||
                  (uId.isNotEmpty && (s.id.trim().toLowerCase() == uId || s.docId.trim().toLowerCase() == uId)),
            );
          } catch (_) {}
        }

        // Resolve display attributes dynamically from synced role models
        final String name = matchedStudent?.name ??
            matchedWarden?.name ??
            matchedHod?.name ??
            matchedCc?.name ??
            updatedUser?.name ??
            user?.name ??
            'User Profile';

        final String email = matchedStudent?.email ??
            matchedWarden?.email ??
            matchedHod?.email ??
            matchedCc?.email ??
            updatedUser?.email ??
            user?.email ??
            'No email provided';

        final String role = (updatedUser?.role.isNotEmpty == true ? updatedUser!.role : (user?.role ?? 'MEMBER')).toUpperCase();

        final String id = matchedStudent?.rollNo ??
            matchedWarden?.id ??
            matchedHod?.id ??
            matchedCc?.id ??
            updatedUser?.erpNo ??
            user?.id ??
            'N/A';

        final String phone = matchedWarden?.phone ??
            matchedHod?.phone ??
            matchedCc?.phone ??
            '';

        final String department = matchedStudent?.department ??
            matchedHod?.department ??
            matchedCc?.section ??
            matchedWarden?.hostelBlock ??
            updatedUser?.department ??
            user?.department ??
            '';

        String getFirstNonEmpty(List<String?> items, {String fallback = ''}) {
          for (var item in items) {
            if (item != null && item.trim().isNotEmpty) return item.trim();
          }
          return fallback;
        }

        final String year = getFirstNonEmpty([
          matchedCc?.yearBatch,
          matchedStudent?.year,
          updatedUser?.year,
          user?.year,
        ], fallback: '3rd Year');

        final String roomNo = matchedStudent?.roomNo.isNotEmpty == true ? matchedStudent!.roomNo : '101';
        final String hostelBlock = matchedStudent?.hostelBlock.isNotEmpty == true
            ? matchedStudent!.hostelBlock
            : (matchedWarden?.hostelBlock.isNotEmpty == true ? matchedWarden!.hostelBlock : 'Engineering');

        Color roleColor;
        switch (roleLower) {
          case 'student':
            roleColor = AppTheme.studentAccent;
            break;
          case 'warden':
            roleColor = AppTheme.wardenAccent;
            break;
          case 'hod':
            roleColor = AppTheme.hodAccent;
            break;
          case 'cc':
          case 'class mam':
          case 'class coordinator':
          case 'class counselor':
            roleColor = const Color(0xFF8B5CF6);
            break;
          default:
            roleColor = AppTheme.adminAccent;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile Details',
              style: GoogleFonts.dmSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: roleColor.withAlpha(30),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: GoogleFonts.dmSans(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: GoogleFonts.dmSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor.withAlpha(60)),
                          ),
                          child: Text(
                            role,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: GoogleFonts.dmSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Divider(height: 24),
                        _ProfileTile(
                          icon: Icons.email_outlined,
                          label: 'Gmail / Email',
                          value: email,
                        ),
                        _ProfileTile(
                          icon: Icons.badge_outlined,
                          label: roleLower == 'student' ? 'ERP no' : 'Staff ID',
                          value: id,
                        ),
                        if (roleLower == 'warden') ...[
                          _ProfileTile(
                            icon: Icons.apartment_rounded,
                            label: 'Assigned Hostel Block',
                            value: hostelBlock,
                          ),
                        ] else if (roleLower == 'hod') ...[
                          _ProfileTile(
                            icon: Icons.school_outlined,
                            label: 'Department',
                            value: department.isNotEmpty ? department : 'Computer Science',
                          ),
                        ] else if (roleLower == 'cc' || roleLower == 'class mam' || roleLower == 'class coordinator' || roleLower == 'class counselor') ...[
                          _ProfileTile(
                            icon: Icons.meeting_room_outlined,
                            label: 'Section',
                            value: department.isNotEmpty ? department : 'Section A',
                          ),
                          if (year.isNotEmpty)
                            _ProfileTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Assigned Year / Batch',
                              value: year,
                            ),
                        ] else if (roleLower == 'student') ...[
                          if (department.isNotEmpty)
                            _ProfileTile(
                              icon: Icons.school_outlined,
                              label: 'Department',
                              value: department,
                            ),
                          if (year.isNotEmpty)
                            _ProfileTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Academic Year',
                              value: year,
                            ),
                          _ProfileTile(
                            icon: Icons.bed_outlined,
                            label: 'Room & Hostel Block',
                            value: 'Room $roomNo • $hostelBlock',
                          ),
                          if (matchedStudent?.assignedWardenName.isNotEmpty == true)
                            _ProfileTile(
                              icon: Icons.shield_outlined,
                              label: 'Assigned Warden',
                              value: matchedStudent!.assignedWardenName,
                            ),
                          if (matchedStudent?.assignedCcName.isNotEmpty == true)
                            _ProfileTile(
                              icon: Icons.person_pin_outlined,
                              label: 'Assigned CC / Class Teacher',
                              value: matchedStudent!.assignedCcName,
                            ),
                          if (matchedStudent?.assignedHodName.isNotEmpty == true)
                            _ProfileTile(
                              icon: Icons.supervisor_account_outlined,
                              label: 'Assigned HOD',
                              value: matchedStudent!.assignedHodName,
                            ),
                        ],
                        if (phone.isNotEmpty)
                          _ProfileTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: phone,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await FirebaseService().clearUserSession();
                        ref.read(currentUserProvider.notifier).state = null;
                        if (context.mounted) {
                          context.go(AppRoutes.initial);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text(
                        'Logout Account',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
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
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
