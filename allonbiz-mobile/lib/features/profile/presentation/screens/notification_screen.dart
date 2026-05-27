import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../data/repositories/notifications_repository.dart';
import 'package:intl/intl.dart';

final notificationsListProvider =
    FutureProvider.autoDispose.family<List<UserNotification>, int>((ref, page) {
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
                        onTap: () async {
                          if (!n.isRead) {
                            await ref.read(notificationsRepositoryProvider).markAsRead(n.id);
                            ref.invalidate(unreadNotificationCountProvider);
                            ref.invalidate(notificationsListProvider);
                          }
                          if (!context.mounted) return;
                          
                          if (n.actionOfferId != null && n.actionOfferId!.isNotEmpty) {
                            context.push('/offer-detail/${n.actionOfferId}');
                          } else if (n.actionShopId != null && n.actionShopId!.isNotEmpty) {
                            context.push('/shop-detail/${n.actionShopId}');
                          }
                        },
                        leading: n.imageUrl != null && n.imageUrl!.isNotEmpty
                            ? AppImage.network(
                                n.imageUrl!,
                                width: 44,
                                height: 44,
                                borderRadius: BorderRadius.circular(10),
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  n.type == 'OfferAlert' || n.type == 'Offer'
                                      ? Icons.local_offer_rounded
                                      : Icons.notifications_rounded,
                                  color: AppColors.primary,
                                ),
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
                            if (n.actionOfferId != null && n.actionOfferId!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sell_rounded, size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text('Tap to view offer', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ] else if (n.actionShopId != null && n.actionShopId!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text('Tap to view shop', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
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
