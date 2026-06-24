import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/theme/app_text_styles.dart';

class SearchSuggestionsList extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final bool isLoading;
  final bool isDark;
  final bool isHistory;
  final Function(PlaceSuggestion) onSelect;

  const SearchSuggestionsList({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.isDark,
    this.isHistory = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    if (isHistory) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion.name),
            avatar: Icon(
              Icons.history_rounded,
              size: 16,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            backgroundColor: isDark ? AppColors.grey800 : AppColors.white.withValues(alpha: 0.5),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: isDark ? AppColors.white : AppColors.grey800,
            ),
            onPressed: () => onSelect(suggestion),
          );
        }).toList(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? AppColors.grey700 : AppColors.grey200,
        ),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: Icon(
              isHistory ? Icons.history_rounded : Icons.location_on_rounded,
              color: AppColors.primary.withValues(alpha: 0.6),
              size: 20,
            ),
            title: Text(
              suggestion.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: isHistory ? null : Text(
              suggestion.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.grey500,
              ),
            ),
            onTap: () => onSelect(suggestion),
          );
        },
      ),
    ),
  ],
),
    );
  }
}
