import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/repositories/favourites_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import '../../../../shared/widgets/offer_card.dart';

final favouritesProvider = FutureProvider.autoDispose<List<SavedItem>>((ref) {
  return ref.watch(favouritesRepositoryProvider).getFavourites();
});

class SavedOffersScreen extends ConsumerStatefulWidget {
  const SavedOffersScreen({super.key});

  @override
  ConsumerState<SavedOffersScreen> createState() => _SavedOffersScreenState();
}

class _SavedOffersScreenState extends ConsumerState<SavedOffersScreen> {
  @override
  Widget build(BuildContext context) {
    final favsAsync = ref.watch(favouritesProvider);

    return AppBarBinding(
      config: AppBarConfig(
        title: const Text('Saved Items'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Scaffold(
        body: favsAsync.when(
          data: (favs) {
            if (favs.isEmpty) {
              return const Center(child: Text('No saved items yet.'));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(favouritesProvider.future),
              child: GridView.builder(
                padding: const EdgeInsets.all(AppDimensions.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.md,
                  mainAxisSpacing: AppDimensions.md,
                  childAspectRatio: 0.72,
                ),
                itemCount: favs.length,
                itemBuilder: (context, index) {
                  final fav = favs[index];
                  final type = fav.type.toLowerCase();

                  if (type == 'offer' && fav.offerId != null) {
                    return OfferCard(
                      title: fav.title,
                      shopName: fav.subtitle,
                      category: 'Offer',
                      discountPercent: fav.discountPercentage ?? 0,
                      distance: '',
                      imageUrl: fav.imageUrl,
                      shopProfileImage: fav.shopProfileImage,
                      onTap: () => context.push(
                        AppRoutes.offerDetail.replaceFirst(':id', fav.offerId!),
                      ),
                    );
                  } else if (type == 'shop' && fav.shopId != null) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push(
                          AppRoutes.shopDetail.replaceFirst(':id', fav.shopId!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: fav.shopProfileImage != null && fav.shopProfileImage!.isNotEmpty
                                  ? Image.network(fav.shopProfileImage!, fit: BoxFit.cover)
                                  : Container(color: AppColors.grey200, child: const Icon(Icons.store_rounded, size: 40, color: AppColors.primary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fav.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(fav.address ?? fav.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
