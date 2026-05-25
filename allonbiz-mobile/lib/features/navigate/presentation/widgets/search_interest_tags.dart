import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/discovery_model.dart';
import '../../../../core/theme/app_text_styles.dart';

class SearchInterestTags extends StatefulWidget {
  final List<TagModel> tags;
  final List<String> selectedInterests;
  final TextEditingController interestSearchController;
  final FocusNode interestFocus;
  final Function(String) onAddCustomInterest;
  final Function(String) onToggleInterest;
  final VoidCallback? onShowAllTags;
  final bool isDark;
  final double? height;
  final bool isCompact;

  const SearchInterestTags({
    super.key,
    required this.tags,
    required this.selectedInterests,
    required this.interestSearchController,
    required this.interestFocus,
    required this.onAddCustomInterest,
    required this.onToggleInterest,
    this.onShowAllTags,
    required this.isDark,
    this.height,
    this.isCompact = false,
  });

  @override
  State<SearchInterestTags> createState() => _SearchInterestTagsState();
}

class _SearchInterestTagsState extends State<SearchInterestTags> {
  static int _globalVisibleCount = 20;

  late final ScrollController _scrollController;
  late int _visibleCount;
  String _searchText = '';
  bool _isAddingTag = false;

  @override
  void initState() {
    super.initState();
    _visibleCount = _globalVisibleCount;
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.interestSearchController.addListener(_onSearchChanged);
    _searchText = widget.interestSearchController.text;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.interestSearchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.isCompact &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchText = widget.interestSearchController.text;
        if (_searchText.isNotEmpty) {
          _visibleCount = 20;
        } else {
          _visibleCount = _globalVisibleCount;
        }
      });
    }
  }

  void _loadMore() {
    final filteredList = _getFilteredTags();
    if (_visibleCount < filteredList.length) {
      setState(() {
        _visibleCount = (_visibleCount + 20).clamp(0, filteredList.length);
        if (_searchText.trim().isEmpty) {
          _globalVisibleCount = _visibleCount;
        }
      });
    }
  }

  List<TagModel> _getFilteredTags() {
    final allTags = widget.tags;
    if (_searchText.trim().isEmpty) {
      return allTags;
    }
    final query = _searchText.toLowerCase().trim();
    return allTags.where((t) => t.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _handleAddNewTag() async {
    final text = widget.interestSearchController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAddingTag = true;
    });

    try {
      await widget.onAddCustomInterest(text);
      widget.interestSearchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tag '$text' added successfully!"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add tag: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTag = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTags = _getFilteredTags();

    // In compact mode, show only 5 tags. In paginated mode, show visible count.
    final visibleTags = widget.isCompact
        ? filteredTags.take(5).toList()
        : filteredTags.take(_visibleCount).toList();

    // Check if we should show the add button
    final queryText = _searchText.trim();
    final hasExactMatch = widget.tags.any(
      (t) => t.name.toLowerCase() == queryText.toLowerCase(),
    );
    final showAddButton = queryText.isNotEmpty && !hasExactMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isCompact) ...[
          Text(
            'WHAT ARE YOU LOOKING FOR?',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.grey800 : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: widget.interestFocus.hasFocus
                  ? colorScheme.primary
                  : Colors.transparent,
              width: 1,
            ),
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
                  controller: widget.interestSearchController,
                  focusNode: widget.interestFocus,
                  onSubmitted: (_) {
                    if (showAddButton) {
                      _handleAddNewTag();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search specific interests...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    fillColor: Colors.transparent,
                    suffixIcon: _isAddingTag
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : showAddButton
                        ? IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: "Add new tag '$queryText'",
                            onPressed: _handleAddNewTag,
                          ).animate().scale(
                            duration: 200.ms,
                            curve: Curves.easeOutBack,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        if (filteredTags.isEmpty && queryText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 32,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No matching tags found.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap the '+' on the right of the search field to add '$queryText'!",
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          widget.isCompact
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...visibleTags.map((tag) => _buildTagChip(tag)),
                    if (widget.onShowAllTags != null)
                      GestureDetector(
                        onTap: widget.onShowAllTags,
                        child: Chip(
                          avatar: const Icon(
                            Icons.more_horiz_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: const Text('More...'),
                          backgroundColor: widget.isDark
                              ? AppColors.grey800
                              : AppColors.grey200,
                          labelStyle: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                )
              : Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...visibleTags.map((tag) => _buildTagChip(tag)),
                            if (_visibleCount < filteredTags.length)
                              GestureDetector(
                                onTap: _loadMore,
                                child: Chip(
                                  avatar: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    'Load More (${filteredTags.length - _visibleCount})',
                                  ),
                                  backgroundColor: widget.isDark
                                      ? AppColors.grey800
                                      : AppColors.grey200,
                                  labelStyle: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildTagChip(TagModel tag) {
    final isSelected = widget.selectedInterests.contains(tag.name);
    return FilterChip(
          label: Text(tag.name),
          selected: isSelected,
          onSelected: (_) => widget.onToggleInterest(tag.name),
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
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          duration: 150.ms,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
        );
  }
}
