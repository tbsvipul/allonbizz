import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<void> submitReport({
    required String reportedItemId,
    required String itemType,
    required String reason,
    String? comments,
    List<String>? evidence,
  }) async {
    final body = {
      'reportedItemId': reportedItemId,
      'itemType': itemType,
      'reason': reason,
      if (comments != null) 'comments': comments,
      if (evidence != null) 'evidence': evidence,
    };

    await _apiClient.post('/user/report', body: body);
  }
}
