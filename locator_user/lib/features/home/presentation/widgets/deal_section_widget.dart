import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/offer_card.dart';
import 'package:locator/l10n/app_localizations.dart';

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
            onActionPressed: () => context.go(AppRoutes.discover),
          ),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 200,
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
                    distance: offer.distance ?? '0 km',
                    onTap: () =>
                        context.push(AppRoutes.offerDetail, extra: offer),
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
