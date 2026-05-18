import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await ref.read(navigationControllerProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationControllerProvider);
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);
    final center =
        nav.currentLocation ??
        const GeoPoint(latitude: 19.076, longitude: 72.8777);

    final markers = <Marker>[
      if (nav.currentLocation != null)
        Marker(
          point: LatLng(
            nav.currentLocation!.latitude,
            nav.currentLocation!.longitude,
          ),
          width: 90,
          height: 90,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeOut(duration: 1200.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.55, 1.55),
                      duration: 1200.ms,
                    ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ...nav.visibleOffers
          .where((offer) => offer.point != null)
          .map(
            (offer) => Marker(
              point: LatLng(offer.point!.latitude, offer.point!.longitude),
              width: 120,
              height: 56,
              child: GestureDetector(
                onTap: () => context.push('/offer/${offer.offerId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offer.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(center.latitude, center.longitude),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? config.darkTileUrl
                    : config.lightTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.allonbiz.mobile',
              ),
              if ((nav.activeRoute?.points.length ?? 0) > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: nav.activeRoute!.points
                          .map((item) => LatLng(item.latitude, item.longitude))
                          .toList(),
                      strokeWidth: 12,
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                    Polyline(
                      points: nav.activeRoute!.points
                          .map((item) => LatLng(item.latitude, item.longitude))
                          .toList(),
                      strokeWidth: 5,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push('/map/search'),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nav.activeJourney?.destinationName ??
                                      nav.currentLocationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nav.activeRoute != null
                                      ? '${nav.activeRoute!.durationMinutes} min • ${nav.activeRoute!.distanceKm.toStringAsFixed(1)} km'
                                      : nav.selectedTags.isEmpty
                                      ? 'Tap to plan a route or start free roam'
                                      : nav.selectedTags.join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (nav.visibleOffers.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _showOffersSheet(context, nav.visibleOffers),
                        icon: const Icon(Icons.local_offer_outlined),
                        label: Text('Offers (${nav.visibleOffers.length})'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: nav.activeJourney == null
                            ? const SizedBox.shrink()
                            : FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: nav.busy
                                    ? null
                                    : () => ref
                                          .read(navigationControllerProvider)
                                          .endJourney(),
                                child: Text(
                                  nav.activeRoute != null
                                      ? 'End Journey'
                                      : 'End Exploration',
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoom_in',
                            onPressed: () {
                              final zoom = _mapController.camera.zoom + 1;
                              _mapController.move(
                                _mapController.camera.center,
                                zoom,
                              );
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out',
                            onPressed: () {
                              final zoom = _mapController.camera.zoom - 1;
                              _mapController.move(
                                _mapController.camera.center,
                                zoom,
                              );
                            },
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton.small(
                            heroTag: 'recenter',
                            onPressed: () async {
                              await ref
                                  .read(navigationControllerProvider)
                                  .refreshCurrentLocation();
                              final point = ref
                                  .read(navigationControllerProvider)
                                  .currentLocation;
                              if (point != null) {
                                _mapController.move(
                                  LatLng(point.latitude, point.longitude),
                                  15,
                                );
                              }
                            },
                            child: const Icon(Icons.my_location_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (nav.busy || nav.statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            if (nav.busy) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(nav.statusMessage ?? 'Working...'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOffersSheet(BuildContext context, List<OfferSummary> offers) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return ListTile(
            title: Text(offer.title),
            subtitle: Text('${offer.shopName}\n${offer.address ?? ''}'),
            isThreeLine: true,
            trailing: offer.discountPercentage == null
                ? null
                : Text('${offer.discountPercentage!.toStringAsFixed(0)}% off'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/offer/${offer.offerId}');
            },
          );
        },
        separatorBuilder: (_, _) => const Divider(),
        itemCount: offers.length,
      ),
    );
  }
}
