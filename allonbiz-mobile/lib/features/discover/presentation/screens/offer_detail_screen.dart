import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_detail_media_header.dart';
import '../../data/repositories/offers_repository.dart';
import 'shop_detail_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';
import '../../../../app/routes/app_routes.dart';

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
  void _showReviewSheet(BuildContext context, String offerId) {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppDimensions.lg,
                right: AppDimensions.lg,
                top: AppDimensions.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write a Review',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setSheetState(() {
                                selectedRating = index + 1;
                              });
                            },
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.secondary,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedRating == 0) {
                            AppSnackbar.show(
                              context,
                              message: 'Please select a rating first',
                              type: AppSnackbarType.error,
                            );
                            return;
                          }
                          try {
                            await ref
                                .read(offersRepositoryProvider)
                                .rateOffer(
                                  offerId,
                                  selectedRating,
                                  reviewController.text.isNotEmpty
                                      ? reviewController.text
                                      : null,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppSnackbar.show(
                                context,
                                message: 'Review submitted successfully!',
                                type: AppSnackbarType.success,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackbar.show(
                                context,
                                message: 'Failed to submit review',
                                type: AppSnackbarType.error,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Submit Review'),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offerId = widget.offerId ?? widget.initialOffer?.id;

    if (offerId == null) {
      return const Center(child: Text('Offer not found'));
    }

    final offerAsync = ref.watch(offerDetailProvider(offerId));
    final offerTitle =
        widget.initialOffer?.title ?? offerAsync.valueOrNull?.title;
    final content = offerAsync.when(
      data: (offer) {
        return _buildContent(context, offer, l10n);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    if (widget.isSheet) {
      return content;
    }

    return AppBarBinding(
      config: AppBarConfig(
        title: Text(offerTitle ?? 'Offer Details'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: content,
    );
  }

  Widget _buildContent(
    BuildContext context,
    Offer offer,
    AppLocalizations l10n,
  ) {
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
                _OfferImageHeader(offer: offer),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.rating?.toStringAsFixed(1) ?? "0.0",
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${offer.reviewCount ?? 0} reviews)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.title,
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
                    Text(
                      offer.shopName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (offer.latitude != 0.0 && offer.longitude != 0.0)
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
                          LatLng(offer.latitude, offer.longitude),
                          offer.shopName,
                          startName: locState.placeName ?? 'Current Location',
                          interests: offer.tags,
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
                  l10n.details,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.5,
                    color: AppColors.grey700,
                  ),
                ),

                if (offer.keeperName != null || offer.keeperPhone != null) ...[
                  const SizedBox(height: AppDimensions.xl),
                  Text(
                    'Keeper Contact',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (offer.keeperName != null && offer.keeperName!.isNotEmpty)
                    Text(
                      'Name: ${offer.keeperName}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                  if (offer.keeperPhone != null &&
                      offer.keeperPhone!.isNotEmpty)
                    Text(
                      'Phone: ${offer.keeperPhone}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                ],

                const SizedBox(height: AppDimensions.xl),
                Text(
                  'Ratings & Reviews',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${offer.rating?.toStringAsFixed(1) ?? "0.0"} out of 5',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Based on ${offer.reviewCount ?? 0} reviews',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey500,
                  ),
                ),

                const SizedBox(height: AppDimensions.xl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReviewSheet(context, offer.id),
                        icon: const Icon(Icons.rate_review_rounded),
                        label: const Text('Write a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () async {
                        try {
                          await ref
                              .read(offersRepositoryProvider)
                              .saveOffer(offer.id);
                          if (context.mounted) {
                            AppSnackbar.show(
                              context,
                              message: 'Offer saved!',
                              type: AppSnackbarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackbar.show(
                              context,
                              message: 'Failed to save offer',
                              type: AppSnackbarType.error,
                            );
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

class _OfferImageHeader extends ConsumerWidget {
  final Offer offer;

  const _OfferImageHeader({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = <String>[];
    var circleImageUrl = offer.shopProfileImage;

    if (offer.imageUrl != null) {
      images.add(offer.imageUrl!);
    }

    if (offer.shopId != null && offer.shopId!.isNotEmpty) {
      final shopAsync = ref.watch(shopDetailProvider(offer.shopId!));
      final shop = shopAsync.valueOrNull;
      if (shop != null) {
        final primaryImageUrl = shop.primaryImageUrl;
        if (primaryImageUrl != null && !images.contains(primaryImageUrl)) {
          images.add(primaryImageUrl);
        }
        if (shop.shopImages.isNotEmpty) {
          for (final img in shop.shopImages) {
            if (!images.contains(img)) {
              images.add(img);
            }
          }
        }
        if (primaryImageUrl != null) {
          circleImageUrl = primaryImageUrl;
        }
      }
    }

    return AppDetailMediaHeader(images: images, avatarImageUrl: circleImageUrl);
  }
}
