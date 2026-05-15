import 'package:flutter/material.dart';
import 'package:locator/core/constants/app_colors.dart';
import 'package:locator/core/constants/app_dimensions.dart';
import 'package:locator/core/models/discovery_model.dart';
import 'package:locator/core/theme/app_text_styles.dart';

class SearchInterestTags extends StatelessWidget {
  final List<TagModel> tags;
  final List<String> selectedInterests;
  final TextEditingController interestSearchController;
  final FocusNode interestFocus;
  final Function(String) onAddCustomInterest;
  final Function(String) onToggleInterest;
  final VoidCallback onShowAllTags;
  final bool isDark;

  const SearchInterestTags({
    super.key,
    required this.tags,
    required this.selectedInterests,
    required this.interestSearchController,
    required this.interestFocus,
    required this.onAddCustomInterest,
    required this.onToggleInterest,
    required this.onShowAllTags,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT ARE YOU LOOKING FOR?',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                color: AppColors.grey500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: interestSearchController,
                  focusNode: interestFocus,
                  onSubmitted: onAddCustomInterest,
                  decoration: InputDecoration(
                    hintText: 'Search specific interests...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    fillColor: Colors.transparent,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => onAddCustomInterest(
                        interestSearchController.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.take(6).map((tag) => _buildTagChip(tag)),
            GestureDetector(
              onTap: onShowAllTags,
              child: Chip(
                label: const Text('View All'),
                backgroundColor: isDark ? AppColors.grey800 : AppColors.grey200,
                labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagChip(TagModel tag) {
    final isSelected = selectedInterests.contains(tag.name);
    return FilterChip(
      label: Text(tag.name),
      selected: isSelected,
      onSelected: (_) => onToggleInterest(tag.name),
      avatar: Icon(
        tag.icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.grey600,
      ),
      backgroundColor: tag.displayColor.withValues(alpha: 0.1),
      selectedColor: tag.displayColor,
      checkmarkColor: Colors.white,
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: isSelected ? Colors.white : AppColors.grey700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
