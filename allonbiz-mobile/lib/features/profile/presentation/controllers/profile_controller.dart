import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(
        profileRepository: ref.watch(profileRepositoryProvider),
        ref: ref,
      );
    });

class ProfileState {
  final bool isLoading;
  final String? error;

  ProfileState({this.isLoading = false, this.error});

  ProfileState copyWith({bool? isLoading, String? error}) {
    return ProfileState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  static const String _genericProfileError =
      'Unable to save your profile right now.';

  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileController({
    required ProfileRepository profileRepository,
    required Ref ref,
  }) : _profileRepository = profileRepository,
       _ref = ref,
       super(ProfileState());

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      // Refresh user in auth state
      await _ref.read(authControllerProvider.notifier).refreshProfile();
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: _genericProfileError);
    }
  }

  Future<void> uploadPhoto(List<int> bytes, String fileName) async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileRepository.uploadPhoto(bytes, fileName);
      // Refresh user in auth state
      await _ref.read(authControllerProvider.notifier).refreshProfile();
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: _genericProfileError);
    }
  }
}
