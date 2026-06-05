import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_image.dart';
import 'app_surface.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.title,
    required this.shopName,
    required this.category,
    required this.discountPercent,
    required this.distance,
    this.imageUrl,
    this.shopProfileImage,
    required this.onTap,
  });

  final String title;
  final String shopName;
  final String category;
  final double discountPercent;
  final String distance;
  final String? imageUrl;
  final String? shopProfileImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactCategory = _compactCategory(category);

    return AppSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.58 : 0.72,
      ),
      borderColor: colorScheme.primary.withValues(alpha: 0.16),
      gradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.82
                : 0.76,
          ),
          colorScheme.primary.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.05
                : 0.08,
          ),
          colorScheme.primaryContainer.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.12
                : 0.18,
          ),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image Area covering background
              AppImage.network(
                (imageUrl != null && imageUrl!.trim().isNotEmpty)
                    ? imageUrl!
                    : (shopProfileImage ?? ''),
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
                height: 140,
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

              // Discount Tag
              Positioned(
                top: AppDimensions.sm,
                left: AppDimensions.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xs,
                    vertical: AppDimensions.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                  ),
                  child: Text(
                    '${discountPercent.toInt()}% OFF',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Text Details (Floating at bottom)
              Positioned(
                left: AppDimensions.sm,
                right: AppDimensions.sm,
                bottom: AppDimensions.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xxs),
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              compactCategory,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (distance.isNotEmpty) ...[
                          const SizedBox(width: AppDimensions.xs),
                          Icon(
                            Icons.location_on_rounded,
                            size: AppDimensions.iconSm,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: AppDimensions.xxs),
                          Flexible(
                            child: Text(
                              distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Offer';
    final normalized = trimmed
        .replaceAll(RegExp(r'\s*&\s*'), ' & ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 18) return normalized;
    return '${normalized.substring(0, 17).trimRight()}…';
  }
}
