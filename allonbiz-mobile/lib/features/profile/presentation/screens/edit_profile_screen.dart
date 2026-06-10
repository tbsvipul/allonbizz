import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_status_banner.dart';
import '../../../../shared/widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    final nameParts = (user?.displayName ?? '').split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  AppBarConfig _buildAppBarConfig(bool isLoading) {
    return AppBarConfig(
      title: const Text('Edit Profile'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
        );
    if (mounted && ref.read(profileControllerProvider).error == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    // Compress by limiting quality to 50
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        await ref.read(profileControllerProvider.notifier).uploadPhoto(bytes.toList(), pickedFile.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return AppBarBinding(
      config: _buildAppBarConfig(state.isLoading),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.grey200,
                          backgroundImage: ref.read(authControllerProvider).user?.photoUrl != null 
                              && ref.read(authControllerProvider).user!.photoUrl!.startsWith('data:image')
                            ? MemoryImage(base64Decode(ref.read(authControllerProvider).user!.photoUrl!.split(',').last)) as ImageProvider
                            : null,
                          child: (ref.read(authControllerProvider).user?.photoUrl == null || !ref.read(authControllerProvider).user!.photoUrl!.startsWith('data:image')) 
                              ? const Icon(Icons.person, size: 50, color: AppColors.grey500) 
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  AppTextField.regular(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'Enter first name',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  AppTextField.regular(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Enter last name',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  AppTextField.regular(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: AppDimensions.md),
                    AppStatusBanner(
                      message: state.error!,
                      variant: AppStatusBannerVariant.error,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
