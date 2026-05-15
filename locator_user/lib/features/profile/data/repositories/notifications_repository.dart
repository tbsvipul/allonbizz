import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/api_response.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiPage<UserNotification>> getNotifications({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _apiClient.get('/user/notifications?pageNumber=$page&pageSize=$pageSize');
      return ApiPage.fromJson(response, (json) => UserNotification.fromJson(json as Map<String, dynamic>));
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
      id: json['notificationId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      metadata: json['metadataJson'],
    );
  }
}
