import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<ApiPage<UserNotification>> getNotifications({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      return await _apiClient.getPage<UserNotification>(
        '/user/notifications?pageNumber=$page&pageSize=$pageSize',
        parser: UserNotification.fromJson,
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.put('/user/notifications/$notificationId/read');
      await _apiClient.invalidateCacheByPrefix('notifications');
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/user/notifications/unread-count');
      return (response.data as Map<String, dynamic>)['data'] as int? ?? 0;
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String type;
  final DateTime sentAt;
  final bool isRead;
  final String? metadata;
  final String? actionOfferId;
  final String? actionShopId;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.type,
    required this.sentAt,
    this.isRead = false,
    this.metadata,
    this.actionOfferId,
    this.actionShopId,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id:
          json['notificationId']?.toString() ??
          json['NotificationId']?.toString() ??
          '',
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      sentAt:
          DateTime.tryParse(
            (json['sentAt'] ?? json['createdAt'] ?? json['CreatedAt'] ?? '')
                .toString(),
          ) ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? json['IsRead'] as bool? ?? false,
      metadata: (json['metadataJson'] ?? json['MetadataJson'])?.toString(),
      actionOfferId: (json['actionOfferId'] ?? json['ActionOfferId'])?.toString(),
      actionShopId: (json['actionShopId'] ?? json['ActionShopId'])?.toString(),
    );
  }
}
