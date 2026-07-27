import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/role_selection_screen/role_selection_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/leave_request_screen/leave_request_screen.dart';
import '../presentation/leave_management_screen/leave_management_screen.dart';
import '../presentation/hod_dashboard_screen/hod_dashboard_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/complaint_screen/complaint_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/';
  static const String splashPreview = '/splash-preview';
  static const String roleSelectionScreen = '/role-selection';
  static const String complaintScreen = '/complaint';
  static const String loginScreen = '/login';
  static const String studentDashboard = '/student-dashboard';
  static const String wardenDashboard = '/warden-dashboard';
  static const String hodDashboard = '/hod-dashboard';
  static const String adminDashboard = '/admin-dashboard';
}

Widget _buildSmoothTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.fastOutSlowIn,
    reverseCurve: Curves.easeInOutCubic,
  );

  return FadeTransition(
    opacity: curvedAnimation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnimation),
      child: child,
    ),
  );
}

Widget _buildSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.fastOutSlowIn,
    reverseCurve: Curves.easeInOutCubic,
  );

  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation),
    child: FadeTransition(
      opacity: curvedAnimation,
      child: child,
    ),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.splashScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.splashPreview,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(forceShow: true),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.roleSelectionScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RoleSelectionScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.complaintScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ComplaintScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) {
        final role = (state.extra as String?) ?? 'student';
        return CustomTransitionPage(
          key: state.pageKey,
          child: LoginScreen(role: role),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: _buildSlideTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.studentDashboard,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LeaveRequestScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.wardenDashboard,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LeaveManagementScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.hodDashboard,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HodDashboardScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.adminDashboard,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminDashboardScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: _buildSmoothTransition,
      ),
    ),
  ],
);
