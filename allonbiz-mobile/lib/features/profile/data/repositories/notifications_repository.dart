import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
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
      return _apiClient.getPage<UserNotification>(
        '/user/notifications?pageNumber=$page&pageSize=$pageSize',
        parser: UserNotification.fromJson,
        options: ApiReadOptions(
          cacheKey: 'notifications:page=$page:size=$pageSize',
          ttl: const Duration(minutes: 5),
        ),
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime sentAt;
  final bool isRead;
  final String? metadata;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sentAt,
    this.isRead = false,
    this.metadata,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id:
          json['notificationId']?.toString() ??
          json['NotificationId']?.toString() ??
          '',
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      sentAt:
          DateTime.tryParse(
            (json['sentAt'] ?? json['createdAt'] ?? json['CreatedAt'] ?? '')
                .toString(),
          ) ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? json['IsRead'] as bool? ?? false,
      metadata: (json['metadataJson'] ?? json['MetadataJson'])?.toString(),
    );
  }
}
