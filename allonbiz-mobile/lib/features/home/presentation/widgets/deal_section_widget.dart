import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/navigation_x.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/offer_card.dart';

class DealSectionWidget extends ConsumerWidget {
  const DealSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.deals,
    required this.l10n,
  });
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Offer> deals;
  final AppLocalizations l10n;







  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(currentLocationProvider).position;

    String formatDistance(double lat, double lon, String? fallback) {
      if (currentLocation == null || (lat == 0 && lon == 0)) {
        return fallback ?? '0 km';
      }
      final meters = LocationService.calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        lat,
        lon,
      );
      if (meters < 1000) {
        return '${meters.toInt()} m';
      }
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: title,
            icon: icon,
            iconColor: iconColor,
            actionLabel: l10n.seeAll,
            onActionPressed: () => context.goTo(AppRoutes.discover),
          ),
          const SizedBox(height: AppDimensions.sm),
          deals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Center(
                    child: Text(
                      'No offers available right now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                    itemCount: deals.length,
                    separatorBuilder: (context, i2) =>
                        const SizedBox(width: AppDimensions.sm),
                    itemBuilder: (context, index) {
                      final offer = deals[index];
                      return RepaintBoundary(
                        child: OfferCard(
                          title: offer.title,
                          shopName: offer.shopName,
                          category: offer.category,
                          discountPercent: offer.discountPercent,
                          distance: formatDistance(
                            offer.latitude,
                            offer.longitude,
                            offer.distance,
                          ),
                          imageUrl: offer.imageUrl,
                          shopProfileImage: offer.shopProfileImage,
                          onTap: () => context.pushTo(
                            AppRoutes.offerDetail.replaceFirst(':id', offer.id),
                            extra: offer,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
