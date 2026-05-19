import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/providers/app_bar_provider.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../data/repositories/offers_repository.dart';

final offerDetailProvider = FutureProvider.family<Offer, String>((ref, id) {
  return ref.watch(offersRepositoryProvider).getOfferDetail(id);
});

class OfferDetailScreen extends ConsumerStatefulWidget {
  final String? offerId;
  final Offer? initialOffer;
  final bool isSheet;

  const OfferDetailScreen({
    super.key,
    this.offerId,
    this.initialOffer,
    this.isSheet = false,
  });

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isSheet) {
      _updateAppBar();
    }
  }

  void _updateAppBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarProvider.notifier).setConfig(
            AppBarConfig(
              title: Text(widget.initialOffer?.title ?? 'Offer Details'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offerId = widget.offerId ?? widget.initialOffer?.id;

    if (offerId == null) {
      return const Center(child: Text('Offer not found'));
    }

    final offerAsync = ref.watch(offerDetailProvider(offerId));

    return offerAsync.when(
      data: (offer) {
        if (!widget.isSheet) {
          // Update app bar with real title if we didn't have it
          if (widget.initialOffer == null) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(appBarProvider.notifier).setConfig(
                  AppBarConfig(
                    title: Text(offer.title),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                );
             });
          }
        }
        return _buildContent(context, offer, l10n);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildContent(BuildContext context, Offer offer, AppLocalizations l10n) {
    final typeColor = offer.category == 'food'
        ? AppColors.pinFood
        : offer.category == 'shopping'
            ? AppColors.pinShopping
            : AppColors.pinSightseeing;

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
                AppImage.network(
                  offer.imageUrl ?? '',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        offer.category.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.title,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.grey500, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      offer.shopName,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                Text(l10n.details, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: AppColors.grey700),
                ),
                const SizedBox(height: AppDimensions.xl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref.read(offersRepositoryProvider).redeemOffer(offer.id);
                            if (context.mounted) {
                              AppSnackbar.show(context, message: l10n.offerRedeemedSuccess, type: AppSnackbarType.success);
                            }
                          } catch (e) {
                             if (context.mounted) {
                              AppSnackbar.show(context, message: 'Failed to redeem offer', type: AppSnackbarType.error);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: Text('Claim Offer', style: AppTextStyles.titleSmall),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () async {
                        try {
                          await ref.read(offersRepositoryProvider).saveOffer(offer.id);
                          if (context.mounted) {
                            AppSnackbar.show(context, message: 'Offer saved!', type: AppSnackbarType.success);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackbar.show(context, message: 'Failed to save offer', type: AppSnackbarType.error);
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark_border_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}
