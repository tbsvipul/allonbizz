import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/offer.dart';

class ArOfferPinWidget extends StatelessWidget {
  const ArOfferPinWidget({super.key, required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final color = offer.category == 'food'
        ? AppColors.pinFood
        : offer.category == 'shopping'
        ? AppColors.pinShopping
        : AppColors.pinSightseeing;
    final icon = offer.category == 'food'
        ? Icons.restaurant_rounded
        : offer.category == 'shopping'
        ? Icons.shopping_bag_rounded
        : Icons.photo_camera_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppDimensions.iconLg),
          const SizedBox(height: 4),
          Text(
            offer.shopName,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${offer.discountPercent.toInt()}% OFF',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
