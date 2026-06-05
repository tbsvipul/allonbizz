import 'dart:convert';

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
      if (response == null || response is! Map) {
        return 0;
      }
      final map = response;
      final data = map['data'] ?? map['Data'];
      if (data is int) return data;
      if (data is num) return data.toInt();
      if (data is String) return int.tryParse(data) ?? 0;
      return 0;
    } catch (e) {
      return 0;
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
  final String? actionJourneyId;
  final String? supportTicketId;
  final String? supportMessageId;
  final String? supportSubject;

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
    this.actionJourneyId,
    this.supportTicketId,
    this.supportMessageId,
    this.supportSubject,
  });

  bool get isSupportReply =>
      supportTicketId != null && supportTicketId!.isNotEmpty;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadataJson'] ?? json['MetadataJson'])?.toString();
    final metadataMap = _decodeMetadata(metadata);

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
      metadata: metadata,
      actionOfferId: (json['actionOfferId'] ?? json['ActionOfferId'])
          ?.toString(),
      actionShopId: (json['actionShopId'] ?? json['ActionShopId'])?.toString(),
      actionJourneyId: (json['actionJourneyId'] ?? json['ActionJourneyId'])
          ?.toString(),
      supportTicketId:
          _metadataValue(metadataMap, 'ticketId') ??
          _metadataValue(metadataMap, 'supportTicketId'),
      supportMessageId:
          _metadataValue(metadataMap, 'messageId') ??
          _metadataValue(metadataMap, 'supportMessageId'),
      supportSubject: _metadataValue(metadataMap, 'subject'),
    );
  }

  static Map<String, dynamic> _decodeMetadata(String? metadata) {
    if (metadata == null || metadata.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(metadata);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    return const {};
  }

  static String? _metadataValue(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
