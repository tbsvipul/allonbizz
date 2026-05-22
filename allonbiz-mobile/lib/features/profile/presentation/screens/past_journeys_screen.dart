import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../trips/data/repositories/journeys_repository.dart';
import '../widgets/journey_card.dart';
import 'journey_detail_screen.dart';

final pastJourneysListProvider = FutureProvider.family<List<JourneyModel>, int>(
  (ref, page) {
    return ref
        .watch(journeysRepositoryProvider)
        .getJourneys(page: page)
        .then((value) => value.items);
  },
);

class PastJourneysScreen extends ConsumerStatefulWidget {
  const PastJourneysScreen({super.key});

  @override
  ConsumerState<PastJourneysScreen> createState() => _PastJourneysScreenState();
}

class _PastJourneysScreenState extends ConsumerState<PastJourneysScreen> {
  static const int _pageSize = 10;

  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final journeysAsync = ref.watch(pastJourneysListProvider(_currentPage));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.pastJourneys),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: journeysAsync.when(
        data: (journeys) {
          if (journeys.isEmpty && _currentPage == 1) {
            return const AppEmptyState(
              title: 'No journeys yet',
              subtitle:
                  'Completed journeys will show up here once you start exploring.',
              icon: Icons.map_outlined,
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
                    return JourneyCard(
                      journey: journey,
                      onTap: journey.id == null
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JourneyDetailScreen(
                                  journeyId: journey.id!,
                                  initialJourney: journey,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPage > 1)
                      TextButton(
                        onPressed: () => setState(() => _currentPage--),
                        child: const Text('Previous'),
                      ),
                    Text('Page $_currentPage'),
                    if (journeys.length >= _pageSize)
                      TextButton(
                        onPressed: () => setState(() => _currentPage++),
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Text(
              'Unable to load journeys.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
