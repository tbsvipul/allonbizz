import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';
import '../profile/profile_screens.dart';

final tripDetailProvider = FutureProvider.family<JourneyDetail?, String?>((
  ref,
  journeyId,
) async {
  if (journeyId == null) {
    return null;
  }
  return ref.read(appRepositoryProvider).getJourneyDetail(journeyId);
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key, this.journeyId});

  final String? journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailProvider(journeyId));
    final journeys = ref.watch(journeysProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trips analytics')),
      body: journeyId == null
          ? journeys.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load journeys: $error')),
              data: (items) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Recent trip snapshots',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...items
                      .take(6)
                      .map(
                        (journey) => Card(
                          child: ListTile(
                            title: Text(
                              journey.destinationName ?? journey.startName,
                            ),
                            subtitle: Text(
                              '${journey.type} • ${journey.durationSeconds ~/ 60} min • ${journey.shopsEncountered.length} encounters',
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            )
          : trip.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load trip: $error')),
              data: (detail) {
                if (detail == null) {
                  return const Center(child: Text('Trip not found.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.endName ?? detail.startName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Started ${DateFormat.yMMMd().add_jm().format(detail.startTime)}',
                            ),
                            if (detail.endTime != null)
                              Text(
                                'Ended ${DateFormat.yMMMd().add_jm().format(detail.endTime!)}',
                              ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                Chip(
                                  label: Text(
                                    '${detail.durationSeconds ~/ 60} min',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${(detail.distanceMeters / 1000).toStringAsFixed(1)} km',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${detail.pathPoints.length} points',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${detail.shopsEncountered.length} encounters',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Interest tags',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: detail.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Shops encountered',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...detail.shopsEncountered.map(
                      (item) => Card(child: ListTile(title: Text(item))),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
