import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/repositories/favourites_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/providers/app_bar_provider.dart';

final favouritesProvider = FutureProvider<List<SavedItem>>((ref) {
  return ref.watch(favouritesRepositoryProvider).getFavourites();
});

class SavedOffersScreen extends ConsumerStatefulWidget {
  const SavedOffersScreen({super.key});

  @override
  ConsumerState<SavedOffersScreen> createState() => _SavedOffersScreenState();
}

class _SavedOffersScreenState extends ConsumerState<SavedOffersScreen> {
  late final AppBarNotifier _appBarNotifier;

  @override
  void initState() {
    super.initState();
    _appBarNotifier = ref.read(appBarProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarNotifier.pushConfig(
        AppBarConfig(
          title: const Text('Saved Items'),
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
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarNotifier.popConfig();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favsAsync = ref.watch(favouritesProvider);

    return Scaffold(
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
              final type = fav.type.toLowerCase();

              if (type == 'offer' && fav.offerId != null) {
                return ListTile(
                  leading: const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(fav.title),
                  subtitle: Text(fav.subtitle),
                  onTap: () => context.push(
                    AppRoutes.offerDetail.replaceAll(':id', fav.offerId!),
                  ),
                );
              } else if (type == 'shop' && fav.shopId != null) {
                return ListTile(
                  leading: const Icon(
                    Icons.store_rounded,
                    color: AppColors.secondary,
                  ),
                  title: Text(fav.title),
                  subtitle: Text(fav.address ?? fav.subtitle),
                  onTap: () => context.push(
                    AppRoutes.shopDetail.replaceAll(':id', fav.shopId!),
                  ),
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
