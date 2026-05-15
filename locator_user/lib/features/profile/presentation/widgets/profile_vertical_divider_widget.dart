import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileVerticalDividerWidget extends StatelessWidget {
  const ProfileVerticalDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.grey300.withValues(alpha: 0.5),
    );
  }
}
