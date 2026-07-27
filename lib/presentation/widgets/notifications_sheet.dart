import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../models/notification_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  int _selectedTabIndex = 0; // 0: All, 1: Unread

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
        return const Color(0xFF10B981); // Green
      case 'rejection':
        return AppTheme.error; // Red
      case 'new_request':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppTheme.primary; // Blue
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
        return Icons.check_circle_rounded;
      case 'rejection':
        return Icons.cancel_rounded;
      case 'new_request':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.erpNo ?? user?.email ?? '';
    final role = user?.role.toLowerCase() ?? '';

    return StreamBuilder<List<AppNotificationModel>>(
      stream: FirebaseService().notificationsStream,
      builder: (context, snapshot) {
        final allNotifications = FirebaseService().getNotificationsForUser(userId, role, user: user);
        final unreadNotifications = allNotifications.where((n) => !n.isRead).toList();
        final displayedNotifications = _selectedTabIndex == 0 ? allNotifications : unreadNotifications;

        return Container(
          height: 80.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.dmSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            unreadNotifications.isNotEmpty
                                ? '${unreadNotifications.length} unread updates'
                                : 'All updates are up to date',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (allNotifications.isNotEmpty) ...[
                      if (unreadNotifications.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            FirebaseService().markAllNotificationsAsRead(userId, role);
                          },
                          icon: const Icon(Icons.done_all_rounded, size: 15),
                          label: Text(
                            'Mark Read',
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseService().clearAllNotificationsForUser(userId, role);
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                        label: Text(
                          'Clear All',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    _buildTabChip(0, 'All (${allNotifications.length})'),
                    const SizedBox(width: 10),
                    _buildTabChip(1, 'Unread (${unreadNotifications.length})'),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Notification List
              Expanded(
                child: displayedNotifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: displayedNotifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = displayedNotifications[index];
                          final typeColor = _getTypeColor(notif.type);
                          final typeIcon = _getTypeIcon(notif.type);

                          return InkWell(
                            onTap: () {
                              if (!notif.isRead) {
                                FirebaseService().markNotificationAsRead(notif.id);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notif.isRead
                                    ? Colors.grey.shade50
                                    : typeColor.withAlpha(12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: notif.isRead
                                      ? Colors.grey.shade200
                                      : typeColor.withAlpha(60),
                                  width: notif.isRead ? 1 : 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: typeColor.withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 12.sp,
                                                  fontWeight: notif.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimeAgo(notif.createdAt),
                                              style: GoogleFonts.dmSans(
                                                fontSize: 9.sp,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif.message,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10.5.sp,
                                            height: 1.35,
                                            color: notif.isRead
                                                ? AppTheme.textSecondary
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!notif.isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        color: typeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      FirebaseService().deleteNotification(notif.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 2),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications here',
            style: GoogleFonts.dmSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Approval and request updates will appear here in real-time.',
            style: GoogleFonts.dmSans(
              fontSize: 10.sp,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
