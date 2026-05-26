import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../data/repositories/shops_repository.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../shared/models/shop.dart';

final shopDetailProvider = FutureProvider.family<Shop, String>((ref, id) {
  return ref.watch(shopsRepositoryProvider).getShopDetail(id);
});

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Shop Details')),
      body: shopAsync.when(
        data: (shop) => _buildContent(context, shop),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Shop shop) {
    final activeOffers = shop.offers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShopImageHeader(shop: shop),
          const SizedBox(height: AppDimensions.lg),
          Text(
            shop.name,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.grey500,
                size: 16,
              ),
              const SizedBox(width: 4),
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
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop.phoneNumber!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
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
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop.email!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (shop.description != null && shop.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'About',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shop.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
          ],

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
                return ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  tileColor: AppColors.grey100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    offer.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    offer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.push(
                      AppRoutes.offerDetail.replaceAll(':id', offer.id),
                      extra: offer,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ShopImageHeader extends StatefulWidget {
  final Shop shop;

  const _ShopImageHeader({required this.shop});

  @override
  State<_ShopImageHeader> createState() => _ShopImageHeaderState();
}

class _ShopImageHeaderState extends State<_ShopImageHeader> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    List<String> images = [];
    if (widget.shop.imageUrl != null && widget.shop.imageUrl!.isNotEmpty) {
      images.add(widget.shop.imageUrl!);
    }
    for (final img in widget.shop.shopImages) {
      if (img.isNotEmpty) {
        images.add(img);
      }
    }

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          // Background Carousel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: images.isNotEmpty
                  ? CarouselSlider(
                      options: CarouselOptions(
                        height: 200,
                        viewportFraction: 1.0,
                        autoPlay: images.length > 1,
                        autoPlayInterval: const Duration(seconds: 3),
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                      ),
                      items: images.map((img) {
                        return AppImage.network(
                          img,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        );
                      }).toList(),
                    )
                  : Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: AppColors.grey400),
                      ),
                    ),
            ),
          ),
          
          // Page Indicator
          if (images.length > 1)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSmoothIndicator(
                    activeIndex: _currentPage,
                    count: images.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      activeDotColor: AppColors.primary,
                      dotColor: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),

          // Circle Image
          Positioned(
            left: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: AppImage.network(
                  widget.shop.imageUrl ?? (widget.shop.shopImages.isNotEmpty ? widget.shop.shopImages.first : ''),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
