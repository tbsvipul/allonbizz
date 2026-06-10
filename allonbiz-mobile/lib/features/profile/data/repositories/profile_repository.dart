import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/app_user.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(apiClient: ref.watch(apiClientProvider));
});

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AppUser> getProfile() async {
    try {
      return await _apiClient.getObject<AppUser>(
        '/user/profile',
        parser: (json) => AppUser.fromJson(json),
        options: const ApiReadOptions(
          cacheKey: 'user:profile',
          ttl: Duration(minutes: 15),
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      await _apiClient.put(
        '/user/profile',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
        },
      );
      await _apiClient.invalidateCacheKey('user:profile');
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<String> uploadPhoto(List<int> bytes, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
      final file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('image', mimeType),
      );
      final response = await _apiClient.postMultipart(
        '/user/profile/photo',
        files: [file],
      );
      final data = response['data'];
      if (data == null || data['photoUrl'] == null) {
        throw const DatabaseFailure('Photo upload failed');
      }
      await _apiClient.invalidateCacheKey('user:profile');
      return data['photoUrl'];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<Map<String, dynamic>> getSavings() async {
    try {
      final response = await _apiClient.get('/user/savings');
      return response['data'] ?? {};
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
