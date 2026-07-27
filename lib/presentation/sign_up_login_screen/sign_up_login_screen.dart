import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_provider.dart';
import './widget/auth_form_widget.dart';
import './widget/brand_header_widget.dart';
import './widget/demo_credentials_widget.dart';
import './widget/role_selector_widget.dart';

class SignUpLoginScreen extends ConsumerStatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  ConsumerState<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends ConsumerState<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    ref.read(selectedRoleProvider.notifier).state = role;
  }

  void _onSignIn() {
    final selectedRole = ref.read(selectedRoleProvider);
    if (selectedRole == 'student') {
      context.go(AppRoutes.studentDashboard);
    } else {
      context.go(AppRoutes.wardenDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final selectedRole = ref.watch(selectedRoleProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 0 : 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 480 : double.infinity,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandHeaderWidget(),
                      const SizedBox(height: 32),
                      RoleSelectorWidget(
                        selectedRole: selectedRole,
                        onRoleChanged: _onRoleChanged,
                      ),
                      const SizedBox(height: 28),
                      AuthFormWidget(
                        selectedRole: selectedRole,
                        onSignIn: _onSignIn,
                      ),
                      const SizedBox(height: 20),
                      DemoCredentialsWidget(selectedRole: selectedRole),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Sign Up',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
