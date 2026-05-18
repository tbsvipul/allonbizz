import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

final discoverFeedProvider =
    FutureProvider<
      ({
        List<CategorySummary> categories,
        List<TagItem> tags,
        List<OfferSummary> trending,
      })
    >((ref) async {
      final repo = ref.read(appRepositoryProvider);
      final categories = await repo.getCategories();
      final tags = await repo.getPublicTags();
      final trending = await repo.getTrendingOffers();
      return (categories: categories, tags: tags, trending: trending);
    });

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(discoverFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load discover feed: $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              readOnly: true,
              onTap: () => context.go('/map/search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Find routes, merchants, and deal interests',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = data.categories[index];
                  return Container(
                    width: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const Spacer(),
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: data.categories.length,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Popular tags',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: data.tags
                  .take(15)
                  .map((tag) => Chip(label: Text(tag.name)))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Featured offers',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...data.trending.map(
              (offer) => Card(
                child: ListTile(
                  title: Text(offer.title),
                  subtitle: Text(
                    '${offer.shopName}\n${offer.category ?? 'General'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/offer/${offer.offerId}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
