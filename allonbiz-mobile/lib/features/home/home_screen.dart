import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

class _HomeBundle {
  const _HomeBundle({
    required this.home,
    required this.savings,
    required this.loyalty,
    required this.trending,
  });

  final UserHomeData home;
  final SavingsSummary savings;
  final LoyaltySummary loyalty;
  final List<OfferSummary> trending;
}

final homeBundleProvider = FutureProvider<_HomeBundle>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  final nav = ref.read(navigationControllerProvider);
  final homeFuture = repo.getHome(
    lat: nav.currentLocation?.latitude,
    lng: nav.currentLocation?.longitude,
  );
  final savingsFuture = repo.getSavings();
  final loyaltyFuture = repo.getLoyalty();
  final trendingFuture = repo.getTrendingOffers();

  final home = await homeFuture;
  final savings = await savingsFuture;
  final loyalty = await loyaltyFuture;
  final trending = await trendingFuture;
  return _HomeBundle(
    home: home,
    savings: savings,
    loyalty: loyalty,
    trending: trending,
  );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final bundle = ref.watch(homeBundleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: bundle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load home: $error')),
        data: (data) {
          final summary = data.home.summary;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeBundleProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${auth.user?.firstName ?? 'traveler'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary.hasActiveJourney
                            ? 'Your ${summary.activeJourneyType} journey is live.'
                            : 'Ready to find offers on the move?',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.tonal(
                        onPressed: () => context.go('/map/search'),
                        child: Text(
                          summary.hasActiveJourney
                              ? 'Manage journey'
                              : 'Start journey',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(label: 'Trips', value: '${summary.totalTrips}'),
                    _MetricCard(
                      label: 'Saved',
                      value: NumberFormat.simpleCurrency().format(
                        data.savings.totalSaved,
                      ),
                    ),
                    _MetricCard(
                      label: 'Points',
                      value: '${data.loyalty.currentPoints}',
                    ),
                    _MetricCard(label: 'Tier', value: data.loyalty.tier),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Quick actions',
                  actionLabel: 'Trips',
                  onTap: () => context.push('/trips'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.map_outlined,
                        title: 'Route planner',
                        subtitle: 'Search destinations and start navigation',
                        onTap: () => context.go('/map/search'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.sell_outlined,
                        title: 'Saved offers',
                        subtitle: 'Open favourites and offline picks',
                        onTap: () => context.push('/profile/saved'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Nearby shops',
                  actionLabel: 'Open map',
                  onTap: () => context.go('/map'),
                ),
                const SizedBox(height: 12),
                ...data.home.nearbyShops.map(
                  (shop) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(shop.name.isNotEmpty ? shop.name[0] : '?'),
                      ),
                      title: Text(shop.name),
                      subtitle: Text(
                        '${shop.address}\n${shop.distanceKm.toStringAsFixed(1)} km away',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/shop/${shop.shopId}'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Featured offers',
                  actionLabel: 'Discover',
                  onTap: () => context.go('/discover'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final offer = data.trending[index];
                      return SizedBox(
                        width: 260,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.push('/offer/${offer.offerId}'),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primaryContainer,
                                  theme.colorScheme.secondaryContainer,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.category ?? 'General',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const Spacer(),
                                Text(
                                  offer.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(offer.shopName),
                                if (offer.discountPercentage != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    '${offer.discountPercentage!.toStringAsFixed(0)}% off',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemCount: data.trending.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
