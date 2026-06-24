import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../data/repositories/shops_repository.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/models/shop.dart';
import '../../../../shared/widgets/app_detail_media_header.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../core/widgets/report_dialog.dart';

final shopDetailProvider = FutureProvider.family<Shop, String>((ref, id) {
  return ref.watch(shopsRepositoryProvider).getShopDetail(id);
});

class ShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;
  final bool isSheet;
  final ScrollController? scrollController;

  const ShopDetailScreen({
    super.key,
    required this.shopId,
    this.isSheet = false,
    this.scrollController,
  });

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));
    final title = shopAsync.valueOrNull?.name ?? 'Shop Details';

    final content = shopAsync.when(
      data: (shop) => _buildContent(context, shop),
      loading: () => const Center(child: AppLoader.inline()),
      error: (err, stack) => AppErrorWidget(
        title: 'Unable to load shop',
        message: '$err',
        onRetry: () => ref.invalidate(shopDetailProvider(widget.shopId)),
      ),
    );

    if (widget.isSheet) {
      return content;
    }

    return AppBarBinding(
      config: AppBarConfig(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_rounded),
            tooltip: 'Report Shop',
            onPressed: () {
              ReportDialog.show(context, reportedItemId: widget.shopId, itemType: 'shop');
            },
          ),
        ],
      ),
      child: Scaffold(backgroundColor: Colors.transparent, body: content),
    );
  }

  Widget _buildContent(BuildContext context, Shop shop) {
    final activeOffers = shop.offers;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        if (widget.isSheet)
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(top: AppDimensions.md)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShopImageHeader(shop: shop),
                const SizedBox(height: AppDimensions.lg),
                GlassmorphicContainer(
                  opacity: Theme.of(context).brightness == Brightness.dark
                      ? 0.88
                      : 0.97,
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shop.address ?? 'No address',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (shop.phoneNumber != null &&
                          shop.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shop.phoneNumber!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (shop.email != null && shop.email!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shop.email!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (shop.description != null &&
                          shop.description!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xl),
                        Text(
                          'About',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shop.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                if (shop.latitude != 0.0 && shop.longitude != 0.0)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      onPressed: () async {
                        final locState = ref.read(currentLocationProvider);
                        if (locState.position == null) {
                          if (context.mounted) {
                            AppSnackbar.show(
                              context,
                              message: 'Current location not available.',
                              type: AppSnackbarType.error,
                            );
                          }
                          return;
                        }
                        final origin = LatLng(
                          locState.position!.latitude,
                          locState.position!.longitude,
                        );
                        final notifier = ref.read(
                          navigationControllerProvider.notifier,
                        );

                        final navState = ref.read(navigationControllerProvider);
                        if (navState.hasActiveJourney) {
                          if (!context.mounted) return;
                          final shouldStartNew = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Active Journey Detected'),
                              content: const Text(
                                'You currently have an active journey. Do you want to end it and start a new journey?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('New Journey'),
                                ),
                              ],
                            ),
                          );

                          if (shouldStartNew != true) return;

                          await notifier.clearRoute();
                        }

                        await notifier.setDestination(
                          origin,
                          LatLng(shop.latitude, shop.longitude),
                          shop.name,
                          startName: locState.placeName ?? 'Current Location',
                        );

                        if (context.mounted) {
                          if (widget.isSheet) {
                            Navigator.of(context).pop();
                          }
                          context.go(AppRoutes.navigate);
                        }
                      },
                      icon: Icons.directions_rounded,
                      label: 'Get Directions',
                    ),
                  ),

                const SizedBox(height: AppDimensions.xl),
                Text(
                  'Active Offers',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (activeOffers.isEmpty)
                  const Text('No active offers at this shop.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeOffers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final offer = activeOffers[index];
                      final offerImageUrl = _resolveOfferImageUrl(offer, shop);
                      final offerTags = _resolveOfferTags(offer, shop);
                      return AppCard(
                        onTap: () {
                          context.push(
                            AppRoutes.offerDetail.replaceAll(':id', offer.id),
                            extra: offer,
                          );
                        },
                        padding: const EdgeInsets.all(12),
                        elevation: 4,
                        borderColor: colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surfaceContainerHighest.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.74
                                  : 0.70,
                            ),
                            colorScheme.primary.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.05
                                  : 0.08,
                            ),
                            colorScheme.primaryContainer.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.10
                                  : 0.16,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: offerImageUrl != null
                                    ? AppImage.network(
                                        offerImageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: _buildOfferPlaceholder(),
                                      )
                                    : _buildOfferPlaceholder(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    offer.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (offerTags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        ...offerTags
                                            .take(4)
                                            .map(
                                              (tag) => _buildHighlightedTagChip(
                                                context,
                                                tag,
                                              ),
                                            ),
                                        if (offerTags.length > 4)
                                          _buildOverflowTagChip(
                                            context,
                                            offerTags.length - 4,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom:
                (widget.isSheet ? 190 : 150) +
                MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: const Icon(
          Icons.shopping_cart_outlined,
          color: AppColors.white,
          size: 28,
        ),
      ),
    );
  }

  String? _resolveOfferImageUrl(Offer offer, Shop shop) {
    for (final candidate in [
      offer.imageUrl,
      offer.shopProfileImage,
      shop.primaryImageUrl,
    ]) {
      final normalized = candidate?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  List<String> _resolveOfferTags(Offer offer, Shop shop) {
    if (offer.tags.isNotEmpty) {
      return _dedupeTags(offer.tags);
    }
    if (shop.tags.isNotEmpty) {
      return _dedupeTags(shop.tags);
    }
    final category = offer.category.trim();
    if (category.isNotEmpty && category.toLowerCase() != 'misc') {
      return [category];
    }
    return const [];
  }

  List<String> _dedupeTags(Iterable<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      final normalized = tag.trim();
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        result.add(normalized);
      }
    }
    return result;
  }

  Widget _buildHighlightedTagChip(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.34 : 0.18),
            colorScheme.primaryContainer.withValues(
              alpha: isDark ? 0.22 : 0.26,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.34 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sell_rounded,
            size: 11,
            color: isDark ? AppColors.accentLight : colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.accentLight : colorScheme.primary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverflowTagChip(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ShopImageHeader extends StatelessWidget {
  final Shop shop;

  const _ShopImageHeader({required this.shop});

  @override
  Widget build(BuildContext context) {
    final images = <String>[];
    final primaryImageUrl = shop.primaryImageUrl;
    if (primaryImageUrl != null && primaryImageUrl.isNotEmpty) {
      images.add(primaryImageUrl);
    }
    for (final img in shop.shopImages) {
      if (img.isNotEmpty && !images.contains(img)) {
        images.add(img);
      }
    }

    return AppDetailMediaHeader(
      images: images,
      avatarImageUrl: primaryImageUrl,
    );
  }
}
