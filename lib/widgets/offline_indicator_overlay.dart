import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class OfflineIndicatorOverlay extends ConsumerStatefulWidget {
  const OfflineIndicatorOverlay({super.key});

  @override
  ConsumerState<OfflineIndicatorOverlay> createState() =>
      _OfflineIndicatorOverlayState();
}

class _OfflineIndicatorOverlayState
    extends ConsumerState<OfflineIndicatorOverlay>
    with SingleTickerProviderStateMixin {
  bool _isDismissed = false;
  bool _isChecking = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
    });

    final isStillOffline = await FirebaseService().checkConnectivityStatus();

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isChecking = false;
        if (!isStillOffline) {
          _isDismissed = false;
        }
      });
      if (isStillOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Still offline. Please check your internet connection.',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineAsync = ref.watch(offlineStreamProvider);
    final isOffline = offlineAsync.value ?? FirebaseService().isOffline;

    // Reset dismissed state when back online
    if (!isOffline && _isDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isDismissed = false;
          });
        }
      });
    }

    if (!isOffline) {
      return const SizedBox.shrink();
    }

    if (_isDismissed) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isDismissed = false;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline Mode (Tap to view details)',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dark Backdrop with blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),

            // Centered Offline Card Indicator
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 85.w,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wifi Off Icon Circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFEE2E2),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFFEF4444),
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Offline Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NO INTERNET CONNECTION',
                            style: GoogleFonts.dmSans(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      'You are Offline',
                      style: GoogleFonts.dmSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Message
                    Text(
                      'Please check your Wi-Fi or mobile data settings and try again.',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 22),

                    // Action Buttons
                    Row(
                      children: [
                        // Dismiss Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isDismissed = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Dismiss',
                              style: GoogleFonts.dmSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Try Again Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isChecking ? null : _handleRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isChecking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Try Again',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
