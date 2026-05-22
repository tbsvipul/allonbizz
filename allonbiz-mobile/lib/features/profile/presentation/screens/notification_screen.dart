import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/repositories/notifications_repository.dart';
import 'package:intl/intl.dart';

final notificationsListProvider =
    FutureProvider.family<List<UserNotification>, int>((ref, page) {
      return ref
          .watch(notificationsRepositoryProvider)
          .getNotifications(page: page)
          .then((value) => value.items);
    });

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(
      notificationsListProvider(_currentPage),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: n.isRead
                          ? Colors.transparent
                          : AppColors.primary.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.grey200),
                      ),
                      child: ListTile(
                        leading: Icon(
                          n.type == 'Offer'
                              ? Icons.local_offer_rounded
                              : Icons.notifications_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          n.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n.message),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat.yMMMd().add_jm().format(n.sentAt),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_currentPage > 1 || notifications.length >= 10)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentPage > 1)
                        TextButton(
                          onPressed: () => setState(() => _currentPage--),
                          child: const Text('Previous'),
                        ),
                      Text('Page $_currentPage'),
                      if (notifications.length >= 10)
                        TextButton(
                          onPressed: () => setState(() => _currentPage++),
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
