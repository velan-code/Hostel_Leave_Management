import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../models/notification_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/system_notification_service.dart';
import './notifications_sheet.dart';

class TopNotificationBannerOverlay extends ConsumerStatefulWidget {
  const TopNotificationBannerOverlay({super.key});

  @override
  ConsumerState<TopNotificationBannerOverlay> createState() =>
      _TopNotificationBannerOverlayState();
}

class _TopNotificationBannerOverlayState
    extends ConsumerState<TopNotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  AppNotificationModel? _activeNotification;
  Timer? _dismissTimer;
  StreamSubscription<List<AppNotificationModel>>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _listenToNotifications();
  }

  static final Set<String> _shownNotifIds = {};

  void _listenToNotifications() {
    _notifSubscription = FirebaseService().notificationsStream.listen((list) {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final userId = user.erpNo.isNotEmpty ? user.erpNo : user.email;
      final role = user.role.toLowerCase();

      final userNotifs = FirebaseService().getNotificationsForUser(userId, role, user: user);
      if (userNotifs.isNotEmpty) {
        final latest = userNotifs.first;
        if (!latest.isRead && !_shownNotifIds.contains(latest.id)) {
          _shownNotifIds.add(latest.id);

          // 1. Always trigger outer OS Native Device Notification Popup
          SystemNotificationService().showNotification(
            id: latest.id.hashCode,
            title: latest.title,
            body: latest.message,
            payload: latest.leaveRequestId,
          );

          // 2. Internal in-app floating banner is suppressed when outer notification is enabled
          final isOuterEnabled = SystemNotificationService().isOuterNotificationEnabled;
          if (!isOuterEnabled) {
            _showBanner(latest);
          }
        }
      }
    });
  }

  void _showBanner(AppNotificationModel notification) {
    _dismissTimer?.cancel();
    setState(() {
      _activeNotification = notification;
    });

    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _hideBanner();
    });
  }

  void _hideBanner() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeNotification = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _notifSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
        return const Color(0xFF10B981); // Emerald Green
      case 'rejection':
        return const Color(0xFFEF4444); // Crimson Red
      case 'new_request':
        return const Color(0xFF8B5CF6); // Royal Purple
      default:
        return const Color(0xFF3B82F6); // Blue Accent
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
        return Icons.verified_rounded;
      case 'rejection':
        return Icons.cancel_rounded;
      case 'new_request':
        return Icons.mark_email_unread_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeNotification == null) {
      return const SizedBox.shrink();
    }

    final notif = _activeNotification!;
    final typeColor = _getTypeColor(notif.type);
    final typeIcon = _getTypeIcon(notif.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _hideBanner();
                    FirebaseService().markNotificationAsRead(notif.id);
                    NotificationsSheet.show(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Dark sleek theme
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: typeColor.withAlpha(150),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            typeIcon,
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeColor.withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'JUST NOW',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w700,
                                        color: typeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10.sp,
                                  color: Colors.white.withAlpha(220),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _hideBanner,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
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
