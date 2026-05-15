import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/journey_model.dart';
import '../../../trips/data/repositories/journeys_repository.dart';

final pastJourneysListProvider = FutureProvider.family<List<JourneyModel>, int>((ref, page) {
  return ref.watch(journeysRepositoryProvider).getJourneys(page: page).then((value) => value.items);
});

class PastJourneysScreen extends ConsumerStatefulWidget {
  const PastJourneysScreen({super.key});

  @override
  ConsumerState<PastJourneysScreen> createState() => _PastJourneysScreenState();
}

class _PastJourneysScreenState extends ConsumerState<PastJourneysScreen> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final journeysAsync = ref.watch(pastJourneysListProvider(_currentPage));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
      appBar: AppBar(
        title: const Text('Past Journeys'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: journeysAsync.when(
        data: (journeys) {
          if (journeys.isEmpty && _currentPage == 1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text('No journeys yet', style: AppTextStyles.titleMedium.copyWith(color: AppColors.grey500)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  itemCount: journeys.length,
                  itemBuilder: (context, index) {
                    final journey = journeys[index];
                    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(journey.startTimeDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimensions.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? AppColors.cardDark : AppColors.white,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    journey.type == JourneyType.destination ? 'Navigation' : 'Free Roam',
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(dateStr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildLocationRow(Icons.circle_outlined, AppColors.primary, journey.startName ?? 'Unknown Start'),
                            const Padding(
                              padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
                              child: SizedBox(height: 20, child: VerticalDivider(width: 1, thickness: 1, color: AppColors.grey300)),
                            ),
                            _buildLocationRow(Icons.location_on_rounded, AppColors.error, journey.endName ?? (journey.type == JourneyType.freeRoam ? 'End Point' : 'Unknown End')),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat(Icons.straighten_rounded, 'Distance', '${(journey.distance / 1000).toStringAsFixed(1)} km'),
                                _buildStat(Icons.timer_outlined, 'Duration', '${(journey.duration / 60).ceil()} min'),
                                _buildStat(Icons.shopping_bag_outlined, 'Shops', '${journey.shopsEncountered.length}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPage > 1)
                      TextButton(onPressed: () => setState(() => _currentPage--), child: const Text('Previous')),
                    Text('Page $_currentPage'),
                    if (journeys.length >= 10)
                      TextButton(onPressed: () => setState(() => _currentPage++), child: const Text('Next')),
                  ],
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.grey500),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500)),
      ],
    );
  }
}
