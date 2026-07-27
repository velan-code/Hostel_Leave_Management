import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/sound_service.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      final savedUser = await FirebaseService().loadSavedUserSession();
      if (!mounted) return;

      if (savedUser != null && savedUser.docId.isNotEmpty) {
        ref.read(currentUserProvider.notifier).state = savedUser;

        final roleLower = savedUser.role.toLowerCase().trim();
        String targetRoute;
        if (roleLower == 'warden') {
          targetRoute = AppRoutes.wardenDashboard;
        } else if (roleLower == 'hod' ||
            roleLower == 'class mam' ||
            roleLower == 'cc' ||
            roleLower == 'class coordinator' ||
            roleLower == 'faculty') {
          targetRoute = AppRoutes.hodDashboard;
        } else if (roleLower == 'admin') {
          targetRoute = AppRoutes.adminDashboard;
        } else {
          targetRoute = AppRoutes.studentDashboard;
        }

        context.go(targetRoute);
        return;
      }
    } catch (e) {
      debugPrint('Error loading saved user session on startup: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A3C5E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
              'Sec Hostel',
                style: GoogleFonts.dmSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060B26),
              Color(0xFF0B1536),
              Color(0xFF0F1B40),
              Color(0xFF060B26),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 1.5.h),
                _buildHeader(),
                SizedBox(height: 3.5.h),
                _buildRoleGrid(context),
                SizedBox(height: 4.h),
                _buildFooter(),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1C42),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: const Color(0xFFE2A748).withAlpha(160),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE2A748).withAlpha(40),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFFE2A748),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sec Hostel',
              style: GoogleFonts.outfit(
                fontSize: 21.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          'Select Portal Role',
          style: GoogleFonts.outfit(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Choose your account type to access dashboard & features',
          style: GoogleFonts.dmSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFE2A748),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _RoleCard(
                role: 'student',
                title: 'Student',
                subtitle: 'Submit & track\nleave requests',
                icon: Icons.school_rounded,
                color: AppTheme.studentAccent,
                onTap: () =>
                    context.push(AppRoutes.loginScreen, extra: 'student'),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              flex: 2,
              child: _RoleCard(
                role: 'warden',
                title: 'Warden',
                subtitle: 'Manage hostel\nleaves',
                icon: Icons.shield_rounded,
                color: AppTheme.wardenAccent,
                onTap: () =>
                    context.push(AppRoutes.loginScreen, extra: 'warden'),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.w),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _RoleCard(
                role: 'cc',
                title: 'Class Coordinator',
                subtitle: 'First-level\napproval',
                icon: Icons.how_to_reg_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () =>
                    context.push(AppRoutes.loginScreen, extra: 'cc'),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              flex: 3,
              child: _RoleCard(
                role: 'hod',
                title: 'HOD',
                subtitle: 'Department head\napproval',
                icon: Icons.supervisor_account_rounded,
                color: AppTheme.hodAccent,
                onTap: () => context.push(AppRoutes.loginScreen, extra: 'hod'),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.w),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: 'admin',
                title: 'Admin',
                subtitle: 'Full system control & user management',
                icon: Icons.admin_panel_settings_rounded,
                color: AppTheme.adminAccent,
                onTap: () =>
                    context.push(AppRoutes.loginScreen, extra: 'admin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          width: 80.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFE2A748).withAlpha(120),
                Colors.transparent,
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Center(
          child: Text(
            'Sec Hostel Leave Management System • Safe & Verified',
            style: GoogleFonts.dmSans(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        SoundService().playTap();
        onTap();
      },
      borderRadius: BorderRadius.circular(22.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: const BoxConstraints(minHeight: 142),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1C42).withAlpha(220),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(color: color.withAlpha(160), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(35),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(icon, size: 72, color: color.withAlpha(30)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withAlpha(45),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: color.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white38,
                      size: 14.sp,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
