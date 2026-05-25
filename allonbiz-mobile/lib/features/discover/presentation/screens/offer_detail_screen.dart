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
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'shop_detail_screen.dart';

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
      ref
          .read(appBarProvider.notifier)
          .setConfig(
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

  void _showReviewSheet(BuildContext context) {
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
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
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
                        onPressed: () {
                          Navigator.pop(context);
                          AppSnackbar.show(
                            context,
                            message: 'Review submitted successfully!',
                            type: AppSnackbarType.success,
                          );
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

    return offerAsync.when(
      data: (offer) {
        if (!widget.isSheet) {
          // Update app bar with real title if we didn't have it
          if (widget.initialOffer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(appBarProvider.notifier)
                  .setConfig(
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
                      '${offer.rating?.toStringAsFixed(1) ?? "0.0"}',
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
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
                    ),
                  if (offer.keeperPhone != null && offer.keeperPhone!.isNotEmpty)
                    Text(
                      'Phone: ${offer.keeperPhone}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
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
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${offer.rating?.toStringAsFixed(1) ?? "0.0"} out of 5',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Based on ${offer.reviewCount ?? 0} reviews',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                ),

                const SizedBox(height: AppDimensions.xl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReviewSheet(context),
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

class _OfferImageHeader extends ConsumerStatefulWidget {
  final Offer offer;

  const _OfferImageHeader({required this.offer});

  @override
  ConsumerState<_OfferImageHeader> createState() => _OfferImageHeaderState();
}

class _OfferImageHeaderState extends ConsumerState<_OfferImageHeader> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _setupTimer() {
    _timer?.cancel();
    if (_images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (!mounted) return;
        if (_currentPage < _images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine images to show
    List<String> images = [];
    String? circleImageUrl = widget.offer.imageUrl;

    if (widget.offer.imageUrl != null) {
      images.add(widget.offer.imageUrl!);
    }

    if (widget.offer.shopId != null && widget.offer.shopId!.isNotEmpty) {
      final shopAsync = ref.watch(shopDetailProvider(widget.offer.shopId!));
      final shop = shopAsync.valueOrNull;
      if (shop != null) {
        if (shop.shopImages.isNotEmpty) {
          for (final img in shop.shopImages) {
            if (!images.contains(img)) {
              images.add(img);
            }
          }
        } else if (shop.imageUrl != null && !images.contains(shop.imageUrl!)) {
          images.add(shop.imageUrl!);
        }
        if (shop.imageUrl != null) {
          circleImageUrl = shop.imageUrl;
        }
      }
    }

    // Update timer if image count changed
    if (images.length != _images.length) {
      _images = images;
      _setupTimer();
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
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        if (mounted) {
                          setState(() {
                            _currentPage = page;
                          });
                        }
                      },
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return AppImage.network(
                          images[index],
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        );
                      },
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
                  child: SmoothPageIndicator(
                    controller: _pageController,
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
                  circleImageUrl ?? '',
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
