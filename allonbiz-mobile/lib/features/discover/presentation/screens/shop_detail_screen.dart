import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../data/repositories/shops_repository.dart';
import '../../../../shared/models/shop.dart';
import '../../../../shared/widgets/app_detail_media_header.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_image.dart';

final shopDetailProvider = FutureProvider.family<Shop, String>((ref, id) {
  return ref.watch(shopsRepositoryProvider).getShopDetail(id);
});

class ShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;
  final bool isSheet;

  const ShopDetailScreen({
    super.key, 
    required this.shopId,
    this.isSheet = false,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
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
      ),
      child: Scaffold(
        body: content,
      ),
    );
  }

  Widget _buildContent(BuildContext context, Shop shop) {
    final activeOffers = shop.offers;

    return CustomScrollView(
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
                Text(
                  shop.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.grey500,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shop.address ?? 'No address',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: AppColors.grey500,
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
                        color: AppColors.grey500,
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
                if (shop.description != null && shop.description!.isNotEmpty) ...[
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
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.xl),
          if (shop.latitude != 0.0 && shop.longitude != 0.0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                return InkWell(
                  onTap: () {
                    context.push(
                      AppRoutes.offerDetail.replaceAll(':id', offer.id),
                      extra: offer,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                                ? AppImage.network(
                                    offer.imageUrl!,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.black87,
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
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (offer.tags.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: offer.tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff57b32c).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff57b32c),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildOfferPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.shopping_cart_outlined,
          color: Colors.orange.shade800,
          size: 28,
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
