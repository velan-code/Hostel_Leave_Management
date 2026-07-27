import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailOrIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailOrIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final roleKey = widget.role.toLowerCase().trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_login_id_$roleKey');
      final savedPass = prefs.getString('saved_login_password_$roleKey');

      if (mounted) {
        if (savedId != null && savedId.isNotEmpty) {
          _emailOrIdController.text = savedId;
          _passwordController.text = savedPass ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials(String id, String pass) async {
    final roleKey = widget.role.toLowerCase().trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_login_id_$roleKey', id);
      await prefs.setString('saved_login_password_$roleKey', pass);
      await prefs.setString('last_used_role', roleKey);
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Map<String, dynamic> get _roleConfig {
    switch (widget.role.toLowerCase()) {
      case 'warden':
        return {
          'label': 'Warden Portal',
          'color': AppTheme.wardenAccent,
          'icon': Icons.shield_rounded,
          'fieldLabel': 'Gmail',
          'hint': 'Enter Gmail',
          'subtitle': 'Log in with your Gmail and password',
          'fieldIcon': Icons.email_outlined,
          'keyboardType': TextInputType.emailAddress,
        };
      case 'cc':
      case 'class mam':
        return {
          'label': 'Class Coordinator Portal',
          'color': const Color(0xFF8B5CF6),
          'icon': Icons.how_to_reg_rounded,
          'fieldLabel': 'Gmail',
          'hint': 'Enter Gmail',
          'subtitle': 'Log in with your Gmail and password',
          'fieldIcon': Icons.email_outlined,
          'keyboardType': TextInputType.emailAddress,
        };
      case 'hod':
        return {
          'label': 'HOD Portal',
          'color': AppTheme.hodAccent,
          'icon': Icons.supervisor_account_rounded,
          'fieldLabel': 'Gmail',
          'hint': 'Enter Gmail',
          'subtitle': 'Log in with your Gmail and password',
          'fieldIcon': Icons.email_outlined,
          'keyboardType': TextInputType.emailAddress,
        };
      case 'admin':
        return {
          'label': 'Admin Portal',
          'color': AppTheme.adminAccent,
          'icon': Icons.admin_panel_settings_rounded,
          'fieldLabel': 'Username',
          'hint': 'Enter Username',
          'subtitle': 'Log in with Admin Username and Password',
          'fieldIcon': Icons.admin_panel_settings_outlined,
          'keyboardType': TextInputType.text,
        };
      default:
        return {
          'label': 'Student Portal',
          'color': AppTheme.studentAccent,
          'icon': Icons.school_rounded,
          'fieldLabel': 'ERP no / Gmail',
          'hint': 'Enter ERP no or Gmail',
          'subtitle': 'Log in with your ERP no or Gmail and password',
          'fieldIcon': Icons.badge_outlined,
          'keyboardType': TextInputType.emailAddress,
        };
    }
  }

  void _login() async {
    final emailOrId = _emailOrIdController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (emailOrId.isEmpty || password.isEmpty) {
      final fieldName = _roleConfig['fieldLabel'] as String;
      setState(() => _errorMessage = 'Please enter your $fieldName and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FirebaseService().loginWithEmail(
        emailOrId,
        password,
        targetRole: widget.role,
      );

      if (!mounted) return;

      if (result['success'] == true && result['user'] != null) {
        TextInput.finishAutofillContext();
        await _saveCredentials(emailOrId, password);

        final UserModel loggedInUser = result['user'] as UserModel;

        ref.read(currentUserProvider.notifier).state = loggedInUser;

        final roleLower = loggedInUser.role.toLowerCase();
        String targetRoute;
        if (roleLower == 'warden') {
          targetRoute = AppRoutes.wardenDashboard;
        } else if (roleLower == 'hod' ||
            roleLower == 'class mam' ||
            roleLower == 'cc' ||
            roleLower == 'faculty') {
          targetRoute = AppRoutes.hodDashboard;
        } else if (roleLower == 'admin') {
          targetRoute = AppRoutes.adminDashboard;
        } else {
          targetRoute = AppRoutes.studentDashboard;
        }

        if (mounted) {
          setState(() => _isLoading = false);
          context.go(targetRoute);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                result['error'] ?? 'Login failed. Please verify credentials.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _roleConfig;
    final Color roleColor = config['color'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopSection(config, roleColor),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 3.h),
                    if (_errorMessage != null) ...[
                      _buildError(),
                      SizedBox(height: 2.h),
                    ],
                    _buildForm(config, roleColor),
                    SizedBox(height: 3.h),
                    _buildLoginButton(roleColor),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(Map<String, dynamic> config, Color roleColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, roleColor.withAlpha(204)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32.0),
          bottomRight: Radius.circular(32.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                config['icon'] as IconData,
                color: Colors.white,
                size: 30,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              config['subtitle'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(220),
              ),
            ),
            Text(
              config['label'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(Map<String, dynamic> config, Color roleColor) {
    final String label = (config['fieldLabel'] as String?) ?? 'Login ID / Email';
    final IconData iconData = (config['fieldIcon'] as IconData?) ?? Icons.badge_outlined;
    final TextInputType keyboardType = (config['keyboardType'] as TextInputType?) ?? TextInputType.text;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _emailOrIdController,
            keyboardType: keyboardType,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            style: GoogleFonts.dmSans(fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: config['hint'] as String,
              hintStyle: GoogleFonts.dmSans(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(
                iconData,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Password',
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            style: GoogleFonts.dmSans(fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Enter password',
              hintStyle: GoogleFonts.dmSans(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.error.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(Color roleColor) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Log In',
                style: GoogleFonts.dmSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
