import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class SearchInputFields extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocus;
  final FocusNode destinationFocus;
  final Function(String) onOriginChanged;
  final Function(String) onDestinationChanged;
  final Function(String) onOriginSubmitted;
  final Function(String) onDestinationSubmitted;
  final VoidCallback onUseCurrentLocation;
  final bool isDark;

  const SearchInputFields({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.originFocus,
    required this.destinationFocus,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onOriginSubmitted,
    required this.onDestinationSubmitted,
    required this.onUseCurrentLocation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('START POINT', AppColors.primaryDark),
        const SizedBox(height: AppDimensions.sm),
        _buildFieldContainer(
          icon: Icons.my_location_rounded,
          iconColor: AppColors.primary,
          child: TextField(
            controller: originController,
            focusNode: originFocus,
            onChanged: onOriginChanged,
            onSubmitted: onOriginSubmitted,
            decoration: _getInputDecoration('Starting Location'),
          ),
          suffix: IconButton(
            icon: const Icon(
              Icons.gps_fixed_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: onUseCurrentLocation,
            tooltip: 'Use Current Location',
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        _buildLabel('DESTINATION', AppColors.primaryDark),
        const SizedBox(height: AppDimensions.sm),
        _buildFieldContainer(
          icon: Icons.location_on_rounded,
          iconColor: AppColors.accent,
          child: TextField(
            controller: destinationController,
            focusNode: destinationFocus,
            onChanged: onDestinationChanged,
            onSubmitted: onDestinationSubmitted,
            decoration: _getInputDecoration('Destination Location'),
          ),
          suffix: ValueListenableBuilder<TextEditingValue>(
            valueListenable: destinationController,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear_rounded, color: AppColors.grey500, size: 20),
                onPressed: () {
                  destinationController.clear();
                  onDestinationChanged('');
                },
                tooltip: 'Clear',
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFieldContainer({
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
          ?suffix,
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      fillColor: Colors.transparent,
    );
  }
}
