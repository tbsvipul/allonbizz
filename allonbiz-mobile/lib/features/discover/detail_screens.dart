import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

final offerDetailProvider = FutureProvider.family<OfferDetail, String>((
  ref,
  offerId,
) {
  return ref.read(appRepositoryProvider).getOfferDetail(offerId);
});

final shopDetailProvider = FutureProvider.family<ShopDetail, String>((
  ref,
  shopId,
) {
  return ref.read(appRepositoryProvider).getShopDetail(shopId);
});

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offerId});

  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(offerDetailProvider(offerId));
    return Scaffold(
      appBar: AppBar(title: const Text('Offer details')),
      body: offer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load offer: $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(data.category ?? 'General')),
                  const Spacer(),
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(data.shopName),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(data.description),
            const SizedBox(height: 20),
            if (data.discountPercentage != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sell_outlined),
                title: Text(
                  '${data.discountPercentage!.toStringAsFixed(0)}% discount',
                ),
                subtitle: Text(
                  'Valid until ${DateFormat.yMMMd().format(data.endDate)}',
                ),
              ),
            if (data.shopAddress != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(data.shopName),
                subtitle: Text(data.shopAddress!),
                onTap: () => context.push('/shop/${data.shopId}'),
              ),
            if (data.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: data.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            ],
            if (data.termsAndConditions != null) ...[
              const SizedBox(height: 24),
              Text(
                'Terms and conditions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(data.termsAndConditions!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(appRepositoryProvider).saveOffer(offerId);
                      ref.invalidate(offerDetailProvider(offerId));
                    },
                    icon: Icon(
                      data.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(data.isSaved ? 'Saved' : 'Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(appRepositoryProvider)
                          .redeemOffer(offerId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer redeemed successfully.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Redeem'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopDetailProvider(shopId));
    return Scaffold(
      appBar: AppBar(title: const Text('Shop details')),
      body: shop.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load shop: $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                child: Text(data.name.isNotEmpty ? data.name[0] : '?'),
              ),
              title: Text(
                data.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(data.address ?? 'Address unavailable'),
              trailing: data.isVerified
                  ? Chip(
                      avatar: const Icon(Icons.verified, size: 18),
                      label: const Text('Verified'),
                    )
                  : null,
            ),
            if (data.description != null) ...[
              const SizedBox(height: 16),
              Text(data.description!),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...data.tags.map((tag) => Chip(label: Text(tag))),
                ...data.amenities.map((item) => Chip(label: Text(item))),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Active offers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...data.recentOffers.map(
              (offer) => Card(
                child: ListTile(
                  title: Text(offer.title),
                  subtitle: Text(
                    'Ends ${DateFormat.yMMMd().format(offer.endDate)}',
                  ),
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
