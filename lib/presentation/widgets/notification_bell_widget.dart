import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/sound_service.dart';
import './notifications_sheet.dart';

class NotificationBellWidget extends ConsumerWidget {
  final Color iconColor;
  final Color backgroundColor;

  const NotificationBellWidget({
    super.key,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x33FFFFFF), // Colors.white.withAlpha(51)
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.erpNo ?? user?.email ?? '';
    final role = user?.role.toLowerCase() ?? '';

    return StreamBuilder<List<AppNotificationModel>>(
      stream: FirebaseService().notificationsStream,
      builder: (context, snapshot) {
        final unreadCount = FirebaseService().getUnreadNotificationCount(userId, role);

        return GestureDetector(
          onTap: () {
            SoundService().playNotification();
            NotificationsSheet.show(context);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  color: iconColor,
                  size: 22,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // Red badge
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
