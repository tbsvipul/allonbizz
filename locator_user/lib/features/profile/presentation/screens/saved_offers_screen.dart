import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/repositories/favourites_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';

final favouritesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(favouritesRepositoryProvider).getFavourites();
});

class SavedOffersScreen extends ConsumerWidget {
  const SavedOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favouritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
      ),
      body: favsAsync.when(
        data: (favs) {
          if (favs.isEmpty) {
            return const Center(child: Text('No saved items yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final fav = favs[index];
              final type = fav['type'];
              final offer = fav['offer'];
              final shop = fav['shop'];

              if (type == 'offer' && offer != null) {
                return ListTile(
                  leading: const Icon(Icons.local_offer_rounded, color: AppColors.primary),
                  title: Text(offer['title'] ?? ''),
                  subtitle: Text(offer['shopName'] ?? ''),
                  onTap: () => context.push(AppRoutes.offerDetail.replaceAll(':id', offer['offerId'])),
                );
              } else if (type == 'shop' && shop != null) {
                return ListTile(
                  leading: const Icon(Icons.store_rounded, color: AppColors.secondary),
                  title: Text(shop['name'] ?? ''),
                  subtitle: Text(shop['address'] ?? ''),
                  onTap: () => context.push(AppRoutes.shopDetail.replaceAll(':id', shop['shopId'])),
                );
              }
              return const SizedBox();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
