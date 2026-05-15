import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_section_header.dart';
import 'package:locator/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_image.dart';
import '../widgets/cat_tile_widget.dart';
import '../../../../core/services/discovery_service.dart';
import '../../data/repositories/deals_repository.dart';

/// Discover Tab – Tab 3.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // AppBar title is managed by MainLayout based on current index.

    final categoriesAsync = ref.watch(categoriesProvider);
    final dealsAsync = ref.watch(dealsProvider);
    final tagsAsync = ref.watch(tagsProvider);

    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: AppDimensions.md)),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: AppTextField.search(
              controller: _searchController,
              hint: l10n.searchHint,
              onChanged: (v) {},
            ),
          ),
        ),

        // Categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: AppSectionHeader(
              title: l10n.categories,
              actionLabel: l10n.seeAll,
              onActionPressed: () {},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: categoriesAsync.when(
              data: (categories) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppDimensions.lg),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return CatTileWidget(
                    icon: cat.icon,
                    label: cat.label,
                    color: cat.color,
                    onTap: () {
                      // Navigate to category search
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),

        // Tags Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: AppSectionHeader(
              title: 'Popular Tags',
              actionLabel: l10n.seeAll,
              onActionPressed: () {},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: tagsAsync.when(
              data: (tags) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                itemCount: tags.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppDimensions.md),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: tag.displayColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tag.displayColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          color: tag.displayColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, _) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Featured Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: AppSectionHeader(
              title: 'Featured Offers',
              actionLabel: l10n.seeAll,
              onActionPressed: () {},
            ),
          ),
        ),

        // Horizontal scroll of cards
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: dealsAsync.when(
              data: (deals) {
                if (deals.isEmpty) {
                  return const Center(child: Text('No offers available'));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                  ),
                  itemCount: deals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppDimensions.lg),
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to offer detail
                      },
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppImage.network(
                                deal.imageUrl ??
                                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        deal.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        deal.shopName,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.only(
            bottom: 120 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }
}
