import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/repositories/notifications_repository.dart';
import 'package:intl/intl.dart';

final notificationsListProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsNotifier,
      List<UserNotification>
    >(NotificationsNotifier.new);

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<UserNotification>> {
  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _isLoadingMore = false;

  @override
  Future<List<UserNotification>> build() async {
    _page = 1;
    final res = await ref
        .read(notificationsRepositoryProvider)
        .getNotifications(page: _page);
    _hasMore = res.items.length >= 10;
    return res.items;
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !_hasMore || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    state = const AsyncLoading<List<UserNotification>>().copyWithPrevious(
      state,
    );

    try {
      _page++;
      final res = await ref
          .read(notificationsRepositoryProvider)
          .getNotifications(page: _page);
      _hasMore = res.items.length >= 10;

      state = AsyncData([...state.requireValue, ...res.items]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAsRead(id);
      ref.invalidate(unreadNotificationCountProvider);

      if (state.hasValue) {
        final currentList = state.requireValue;
        final index = currentList.indexWhere((n) => n.id == id);
        if (index != -1) {
          final n = currentList[index];
          final updatedList = List<UserNotification>.from(currentList);
          updatedList[index] = UserNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            imageUrl: n.imageUrl,
            type: n.type,
            sentAt: n.sentAt,
            isRead: true,
            metadata: n.metadata,
            actionOfferId: n.actionOfferId,
            actionShopId: n.actionShopId,
            actionJourneyId: n.actionJourneyId,
            supportTicketId: n.supportTicketId,
            supportMessageId: n.supportMessageId,
            supportSubject: n.supportSubject,
          );
          state = AsyncData(updatedList);
        }
      }
    } catch (e) {
      // Ignore error for now, UI can handle or fail silently
    }
  }
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notifications')),
      body: GradientBackground(
        child: notificationsAsync.when(
          skipLoadingOnReload: true,
          data: (notifications) {
            if (notifications.isEmpty) {
              return const AppEmptyState(
                title: 'No notifications yet',
                subtitle:
                    'Nearby deal alerts and journey updates will appear here.',
                icon: Icons.notifications_none_rounded,
              );
            }

            final hasMore = ref
                .read(notificationsListProvider.notifier)
                .hasMore;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsListProvider);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppDimensions.md),
                itemCount: notifications.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final n = notifications[index];
                  final notificationIcon = n.isSupportReply
                      ? Icons.support_agent_rounded
                      : (n.type == 'OfferAlert' || n.type == 'Offer')
                      ? Icons.local_offer_rounded
                      : Icons.notifications_rounded;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      borderColor: n.isRead
                          ? null
                          : AppColors.secondary.withValues(alpha: 0.42),
                      onTap: () async {
                        if (!n.isRead) {
                          await ref
                              .read(notificationsListProvider.notifier)
                              .markAsRead(n.id);
                        }
                        if (!context.mounted) return;

                        if (n.isSupportReply) {
                          context.push(
                            '/notifications/support-reply/${n.id}',
                            extra: n,
                          );
                        } else if (n.actionOfferId != null &&
                            n.actionOfferId!.isNotEmpty) {
                          context.push('/offer-detail/${n.actionOfferId}');
                        } else if (n.actionShopId != null &&
                            n.actionShopId!.isNotEmpty) {
                          context.push('/shop-detail/${n.actionShopId}');
                        }
                      },
                      child: ListTile(
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  notificationIcon,
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
                            if (n.isSupportReply) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.support_agent_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap to view reply',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (n.actionOfferId != null &&
                                n.actionOfferId!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sell_rounded,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap to view offer',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (n.actionShopId != null &&
                                n.actionShopId!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.storefront_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap to view shop',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: AppLoader.inline()),
          error: (err, stack) => AppErrorWidget(
            title: 'Unable to load notifications',
            message: '$err',
            onRetry: () => ref.invalidate(notificationsListProvider),
          ),
        ),
      ),
    );
  }
}
