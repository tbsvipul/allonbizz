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

final shopDetailProvider = FutureProvider.family<Shop, String>((ref, id) {
  return ref.watch(shopsRepositoryProvider).getShopDetail(id);
});

class ShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));
    final title = shopAsync.valueOrNull?.name ?? 'Shop Details';

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
        body: shopAsync.when(
          data: (shop) => _buildContent(context, shop),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
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
