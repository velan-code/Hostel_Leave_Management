import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../services/firebase_service.dart';
import '../../services/system_notification_service.dart';
import '../../services/push_notification_service.dart';
import '../../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  final bool forceShow; // Allow forcing splash screen for testing if needed
  const SplashScreen({super.key, this.forceShow = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late AnimationController _pulseAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<double> _cardsSlideAnim;

  bool _isFirstOpen = true;

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _logoScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    _cardsSlideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _checkFirstOpenAndInit();
  }

  Future<void> _checkFirstOpenAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;

    // Load user session if already logged in
    final savedUser = await FirebaseService().loadSavedUserSession();

    // If not forced and already seen splash on previous app open, bypass splash screen
    if (!widget.forceShow && hasSeenSplash) {
      setState(() => _isFirstOpen = false);
      if (mounted) {
        _navigateNext(savedUser);
      }
      return;
    }

    // First open flow: Start animation & request notification permission
    _mainAnimController.forward();

    try {
      // Ask permission for notifications on first open
      await SystemNotificationService().requestNotificationPermission();
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint('Error asking notification permissions: $e');
    }

    // Save flag that splash has been shown
    await prefs.setBool('has_seen_splash', true);

    // Display splash screen for 6 seconds on first open
    await Future.delayed(const Duration(seconds: 6));

    if (mounted) {
      _navigateNext(savedUser);
    }
  }

  void _navigateNext(UserModel? user) {
    if (user != null) {
      final role = user.role.toLowerCase();
      if (role == 'student') {
        context.go(AppRoutes.studentDashboard);
        return;
      } else if (role == 'warden') {
        context.go(AppRoutes.wardenDashboard);
        return;
      } else if (role == 'hod') {
        context.go(AppRoutes.hodDashboard);
        return;
      } else if (role == 'admin') {
        context.go(AppRoutes.adminDashboard);
        return;
      }
    }
    context.go(AppRoutes.roleSelectionScreen);
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _pulseAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not first open, render instant black container while navigating
    if (!_isFirstOpen && !widget.forceShow) {
      return const Scaffold(
        backgroundColor: Color(0xFF060B26),
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Rich Deep Navy Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF091136),
                  Color(0xFF060B26),
                  Color(0xFF030617),
                ],
              ),
            ),
          ),

          // 2. Ambient Wave Lines Custom Painter Background
          CustomPaint(
            painter: _WavePatternPainter(),
            size: Size.infinite,
          ),

          // 3. Main Content Layout
          SafeArea(
            child: AnimatedBuilder(
              animation: _mainAnimController,
              builder: (context, child) {
                return Column(
                  children: [
                    SizedBox(height: 2.h),

                    // Top Logo Badge
                    Transform.scale(
                      scale: _logoScaleAnim.value,
                      child: Container(
                        width: 95,
                        height: 95,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE2A748),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE2A748).withAlpha(120),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF0F1C42),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: Color(0xFFE2A748),
                                  size: 44,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Main Title Header
                    Opacity(
                      opacity: _titleFadeAnim.value,
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'HOSTEL LEAVE\n',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'MANAGEMENT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE5A638),
                                    letterSpacing: 2.0,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 1.2.h),

                          // Gold Line with Center Dot Divider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFFE2A748),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2A748),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFE2A748),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 1.2.h),

                          // Subtitle Tagline
                          Text(
                            'EASY REQUEST  •  QUICK APPROVAL  •  SECURE TRACKING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.5.h),

                    // 3 Feature Glass Cards Row
                    Transform.translate(
                      offset: Offset(0, _cardsSlideAnim.value),
                      child: Opacity(
                        opacity: _titleFadeAnim.value,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFeatureCard(
                                icon: Icons.description_rounded,
                                badgeColor: const Color(0xFF29B6F6),
                                label: 'REQUEST',
                              ),
                              _buildFeatureCard(
                                icon: Icons.person_rounded,
                                badgeColor: const Color(0xFF66BB6A),
                                label: 'APPROVE',
                              ),
                              _buildFeatureCard(
                                icon: Icons.assignment_turned_in_rounded,
                                badgeColor: const Color(0xFFAB47BC),
                                label: 'TRACK',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Middle Section: Animated Smart Digital Gate Pass Hub
                    _buildDigitalGatePassCard(),

                    // Bottom Customized Dark Gold Accent Card Sheet
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 2.2.h, horizontal: 6.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0F1B40),
                            Color(0xFF0A122E),
                            Color(0xFF060B20),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFFE2A748).withAlpha(180),
                            width: 1.8,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE2A748).withAlpha(40),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                          const BoxShadow(
                            color: Colors.black45,
                            blurRadius: 25,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Handle Pill
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2A748).withAlpha(140),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Text(
                            'Smart Leave Management',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Simplified  •  Transparent  •  Trusted',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE5A638),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color badgeColor,
    required String label,
  }) {
    return Container(
      width: 27.w,
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: const Color(0xFF101B46).withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: badgeColor,
                  size: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalGatePassCard() {
    return AnimatedBuilder(
      animation: _pulseAnimController,
      builder: (context, child) {
        final pulseValue = _pulseAnimController.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1C42).withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2A748).withAlpha(100 + (pulseValue * 120).toInt()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE2A748).withAlpha(30 + (pulseValue * 60).toInt()),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2A748).withAlpha(35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFFE2A748),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SMART DIGITAL GATE PASS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instant • Paperless • Multi-tier Approval',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 8.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981).withAlpha(150),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 7.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
                      Stack(
                        children: [
                          Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.white10,
                          ),
                          Positioned(
                            left: (MediaQuery.of(context).size.width * 0.55) * pulseValue,
                            child: Container(
                              height: 2,
                              width: 70,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFFE2A748),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniBadge(
                            icon: Icons.flash_on_rounded,
                            label: 'Fast Pass',
                            color: const Color(0xFF4FC3F7),
                          ),
                          _buildMiniBadge(
                            icon: Icons.shield_rounded,
                            label: 'Encrypted',
                            color: const Color(0xFF81C784),
                          ),
                          _buildMiniBadge(
                            icon: Icons.notifications_active_rounded,
                            label: 'Live Alerts',
                            color: const Color(0xFFBA68C8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13.sp),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ──────────────────── CUSTOM PAINTERS FOR NATIVE SPLASH GRAPHICS ────────────────────

class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.cubicTo(
      size.width * 0.4,
      size.height * 0.15,
      size.width * 0.6,
      size.height * 0.28,
      size.width,
      size.height * 0.22,
    );

    path.moveTo(0, size.height * 0.65);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.60,
      size.width * 0.7,
      size.height * 0.72,
      size.width,
      size.height * 0.68,
    );

    canvas.drawPath(path, paint);

    // Glow circle background
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E3A8A).withAlpha(80),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.4),
        radius: size.width * 0.6,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      size.width * 0.6,
      radialPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
