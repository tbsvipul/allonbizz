import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/discovery_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../features/navigate/presentation/controllers/navigation_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/models/shop.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/user_discover_response.dart';
import '../../data/repositories/user_discover_repository.dart';

/// Discover Tab - API-backed personalized offers, shops, categories, and tags.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _searchDebounce;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final Set<String> _selectedTags = {};

  bool get _hasFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedTags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  void _toggleCategory(CategoryModel category) {
    setState(() {
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
      } else {
        _selectedCategoryId = category.id;
        _selectedCategoryName = category.label;
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedTags.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(
      currentLocationProvider.select((location) => location.position),
    );
    final radiusMeters = ref.watch(discoveryRadiusProvider);
    final query = UserDiscoverQuery(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
      category: _selectedCategoryName,
      tags: _selectedTags.toList(growable: false),
      lat: position?.latitude,
      lng: position?.longitude,
      radiusKm: radiusMeters / 1000,
      limit: 30,
      includeTaxonomy: true,
    );
    final discoverAsync = ref.watch(userDiscoverProvider(query));
    final data = discoverAsync.valueOrNull ?? UserDiscoverResponse.empty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _searchFocusNode.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.only(top: AppDimensions.md),
              ),
              _buildSearch(context),
              if (_hasFilters) _buildActiveFilters(),
              if (discoverAsync.hasError && discoverAsync.valueOrNull == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorWidget(
                    title: 'Discover unavailable',
                    message: discoverAsync.error.toString(),
                    onRetry: () => ref.invalidate(userDiscoverProvider(query)),
                  ),
                )
              else ...[
                _buildOffers(data.offers, discoverAsync.isLoading, data.personalization),
                _buildShops(data.shops, data.personalization),
                if (!discoverAsync.isLoading &&
                    data.offers.isEmpty &&
                    data.shops.isEmpty)
                  SliverToBoxAdapter(
                    child: AppEmptyState(
                      title: 'No matches found',
                      subtitle:
                          'Try removing a filter or expanding your discovery radius.',
                      icon: Icons.explore_off_rounded,
                      actionLabel: _hasFilters ? 'Clear filters' : null,
                      onAction: _hasFilters ? _clearFilters : null,
                    ),
                  ),
              ],
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 178 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
        if (_searchQuery.isNotEmpty && _searchFocusNode.hasFocus)
          Positioned(
            top: AppDimensions.md + 66,
            left: AppDimensions.lg,
            right: AppDimensions.lg,
            child: _buildFloatingSearchSuggestions(
              categories: data.categories,
              tags: data.tags,
              isLoading: discoverAsync.isLoading,
            ),
          ),
      ],
    );
  }

  SliverToBoxAdapter _buildSearch(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
        child: AppTextField.search(
          controller: _searchController,
          focusNode: _searchFocusNode,
          hint: l10n.searchHint,
          onChanged: _handleSearchChanged,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          onSubmitted: (value) {
            _searchDebounce?.cancel();
            setState(() => _searchQuery = value.trim());
            _searchFocusNode.unfocus();
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildActiveFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    final chips = <Widget>[
      if (_searchQuery.isNotEmpty)
        _FilterChipPill(
          label: _searchQuery,
          icon: Icons.search_rounded,
          onDeleted: () {
            _searchDebounce?.cancel();
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
      if (_selectedCategoryName != null)
        _FilterChipPill(
          label: _selectedCategoryName!,
          icon: Icons.category_rounded,
          onDeleted: () {
            setState(() {
              _selectedCategoryId = null;
              _selectedCategoryName = null;
            });
          },
        ),
      for (final tag in _selectedTags)
        _FilterChipPill(
          label: tag,
          icon: Icons.sell_rounded,
          onDeleted: () => _toggleTag(tag),
        ),
      TextButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Clear'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          visualDensity: VisualDensity.compact,
        ),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.lg,
          AppDimensions.md,
          AppDimensions.lg,
          0,
        ),
        child: Wrap(
          spacing: AppDimensions.xs,
          runSpacing: AppDimensions.xs,
          children: chips,
        ),
      ),
    );
  }

  Widget _buildFloatingSearchSuggestions({
    required List<CategoryModel> categories,
    required List<TagModel> tags,
    required bool isLoading,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    final categorySuggestions = categories
        .where((category) => category.label.toLowerCase().contains(query))
        .toList(growable: false);
    final tagSuggestions = tags
        .where((tag) => tag.name.toLowerCase().contains(query))
        .toList(growable: false);

    if (categorySuggestions.isEmpty && tagSuggestions.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    final maxHeight = (MediaQuery.sizeOf(context).height * 0.38)
        .clamp(180.0, 320.0)
        .toDouble();

    return Material(
      color: Colors.transparent,
      elevation: 18,
      borderRadius: BorderRadius.circular(22),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child:
              isLoading && categorySuggestions.isEmpty && tagSuggestions.isEmpty
              ? const Center(child: AppLoader.inline(size: 22))
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const PremiumIconBadge(
                              icon: Icons.tips_and_updates_rounded,
                              color: AppColors.secondary,
                              size: 34,
                              iconSize: 17,
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Text(
                                'Search suggestions',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        if (categorySuggestions.isNotEmpty) ...[
                          _SuggestionSectionLabel(
                            icon: Icons.category_rounded,
                            label: 'Categories',
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Wrap(
                            spacing: AppDimensions.xs,
                            runSpacing: AppDimensions.xs,
                            children: [
                              for (final category in categorySuggestions)
                                _SuggestionPill(
                                  label: category.label,
                                  icon: category.icon,
                                  color: category.color,
                                  selected: _selectedCategoryId == category.id,
                                  onTap: () => _toggleCategory(category),
                                ),
                            ],
                          ),
                        ],
                        if (categorySuggestions.isNotEmpty &&
                            tagSuggestions.isNotEmpty)
                          const SizedBox(height: AppDimensions.md),
                        if (tagSuggestions.isNotEmpty) ...[
                          _SuggestionSectionLabel(
                            icon: Icons.local_offer_rounded,
                            label: 'Tags',
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Wrap(
                            spacing: AppDimensions.xs,
                            runSpacing: AppDimensions.xs,
                            children: [
                              for (final tag in tagSuggestions)
                                _SuggestionPill(
                                  label: tag.name,
                                  icon: tag.icon,
                                  color: tag.displayColor,
                                  selected: _selectedTags.contains(tag.name),
                                  onTap: () => _toggleTag(tag.name),
                                ),
                            ],
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

  Widget _buildOffers(List<DiscoverOfferResult> offers, bool isLoading, UserDiscoverPersonalization personalization) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  title: personalization.hasHistory ? 'Exclusive for You' : 'Trending Offers',
                  icon: personalization.hasHistory ? Icons.workspace_premium_rounded : Icons.local_fire_department_rounded,
                  iconColor: AppColors.secondary,
                ),
                
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 276,
            child: isLoading && offers.isEmpty
                ? const Center(child: AppLoader.inline())
                : offers.isEmpty
                ? const Center(child: Text('No offers available'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                    ),
                    itemCount: offers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppDimensions.md),
                    itemBuilder: (context, index) {
                      return _DiscoverOfferCard(
                        result: offers[index],
                        onTap: () => _openOffer(offers[index].offer),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildShops(List<DiscoverShopResult> shops, UserDiscoverPersonalization personalization) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  title: personalization.hasHistory ? 'Recommended Shops' : 'Popular Shops',
                  icon: Icons.storefront_rounded,
                ),
                
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemCount: shops.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              child: _DiscoverShopCard(
                result: shops[index],
                onTap: () => _openShop(shops[index].shop),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openOffer(Offer offer) {
    context.push(
      AppRoutes.offerDetail.replaceFirst(':id', offer.id),
      extra: offer,
    );
  }

  void _openShop(Shop shop) {
    context.push(AppRoutes.shopDetail.replaceFirst(':id', shop.id));
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = color == const Color(0xFF9E9E9E)
        ? colorScheme.primary
        : color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  resolvedColor.withValues(alpha: 0.26),
                  AppColors.secondary.withValues(alpha: 0.24),
                ],
              )
            : null,
        color: selected ? null : resolvedColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? resolvedColor.withValues(alpha: 0.58)
              : resolvedColor.withValues(alpha: 0.22),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : icon,
                  color: selected ? colorScheme.primary : resolvedColor,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? colorScheme.primary : resolvedColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionSectionLabel extends StatelessWidget {
  const _SuggestionSectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.icon,
    required this.onDeleted,
  });

  final String label;
  final IconData icon;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: AppDimensions.sm),
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: EdgeInsets.zero,
            onPressed: onDeleted,
            icon: const Icon(Icons.close_rounded, size: 16),
          ),
        ],
      ),
    );
  }
}

class _DiscoverOfferCard extends StatelessWidget {
  const _DiscoverOfferCard({required this.result, required this.onTap});

  final DiscoverOfferResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offer = result.offer;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassmorphicContainer(
      onTap: onTap,
      width: 210,
      borderRadius: BorderRadius.circular(26),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image covering full background
            AppImage.network(
              (offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty)
                  ? offer.imageUrl!
                  : (offer.shopProfileImage ?? ''),
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppColors.grey200,
                alignment: Alignment.center,
                child: Icon(
                  Icons.local_offer_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
            ),

            // Gradient Overlay for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.6),
                      AppColors.black.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Discount Badge
            if (offer.discountPercent > 0)
              Positioned(
                top: AppDimensions.sm,
                left: AppDimensions.sm,
                child: _LuxuryBadge(
                  label: '${offer.discountPercent.toStringAsFixed(0)}% OFF',
                  color: AppColors.accent,
                ),
              ),

            // Floating Text Details
            Positioned(
              left: AppDimensions.sm,
              right: AppDimensions.sm,
              bottom: AppDimensions.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _FloatingTag(label: offer.category),
                      for (final tag in offer.tags.take(1))
                        _FloatingTag(label: tag),
                      if (result.distanceKm != null)
                        _FloatingTag(
                          label: '${result.distanceKm!.toStringAsFixed(1)} km',
                          icon: Icons.location_on_rounded,
                        )
                      else if (result.matchReason.isNotEmpty)
                        _FloatingTag(label: result.matchReason),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: AppColors.white),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                height: 1,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverShopCard extends StatelessWidget {
  const _DiscoverShopCard({required this.result, required this.onTap});

  final DiscoverShopResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shop = result.shop;
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = shop.primaryImageUrl ?? '';

    return GlassmorphicContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.md),
      borderRadius: BorderRadius.circular(26),
      child: Row(
        children: [
          AppImage.network(
            imageUrl,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      shop.isOpen
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: shop.isOpen
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  result.matchReason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniTag(label: result.category),
                    if (result.activeOfferCount > 0)
                      _MiniTag(label: '${result.activeOfferCount} offers'),
                    if (result.distanceKm != null)
                      _MiniTag(
                        label: '${result.distanceKm!.toStringAsFixed(1)} km',
                      ),
                    for (final tag in shop.tags.take(2)) _MiniTag(label: tag),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
        ],
      ),
    );
  }
}

class _LuxuryBadge extends StatelessWidget {
  const _LuxuryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.44)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
