import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/app_colors.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/features/notifications/bloc/notification_cubit.dart';
import 'package:state/features/notifications/bloc/notification_state.dart';
import 'package:state/features/notifications/ui/widgets/notification_item.dart';
import 'package:state/service_locator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      if (state is NotificationLoaded &&
                          state.unreadCount > 0) {
                        return TextButton(
                          onPressed: () {
                            context.read<NotificationCubit>().markAllAsRead();
                          },
                          child: Text(
                            'Mark all as read',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is NotificationError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is NotificationLoaded) {
                    if (state.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await context
                            .read<NotificationCubit>()
                            .refreshNotifications();
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          // Load more when user scrolls to 80% of current content
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent * 0.8) {
                            context
                                .read<NotificationCubit>()
                                .loadMoreNotifications();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount:
                              state.notifications.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Loading indicator at bottom
                            if (index == state.notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final notification = state.notifications[index];
                            return NotificationItem(
                              notification: notification,
                              onTap: () {
                                // Mark as read
                                context.read<NotificationCubit>().markAsRead(
                                  notification.id,
                                );

                                // Navigate to post
                                final navigationService =
                                    sl<INavigationService>();
                                navigationService.goToPostDetails(
                                  context,
                                  notification.postId,
                                  commentId: notification.commentId,
                                );
                              },
                              onDelete: () {
                                context
                                    .read<NotificationCubit>()
                                    .deleteNotification(notification.id);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
