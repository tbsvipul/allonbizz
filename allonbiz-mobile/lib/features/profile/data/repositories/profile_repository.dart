import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
      final response = await _apiClient.get('/user/profile');
      final data = response['data'];
      if (data == null) throw const DatabaseFailure('Profile data not found');
      return AppUser.fromJson(data);
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
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<String> uploadPhoto(List<int> bytes, String fileName) async {
    try {
      final file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      final response = await _apiClient.postMultipart(
        '/user/profile/photo',
        files: [file],
      );
      final data = response['data'];
      if (data == null || data['photoUrl'] == null) {
        throw const DatabaseFailure('Photo upload failed');
      }
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

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _apiClient.get('/user/loyalty/wallet');
      return response['data'] ?? {};
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
