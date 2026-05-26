import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';

import '../../../../core/services/discovery_service.dart';
import '../../../../core/models/discovery_model.dart';

class InterestsDialogWidget extends ConsumerStatefulWidget {
  const InterestsDialogWidget({super.key});

  @override
  ConsumerState<InterestsDialogWidget> createState() =>
      _InterestsDialogWidgetState();
}

class _InterestsDialogWidgetState extends ConsumerState<InterestsDialogWidget> {
  final _searchController = TextEditingController();
  final ValueNotifier<Set<String>> _selectedTags = ValueNotifier({});
  final List<TagModel> _customTags = [];
  bool _isStartingJourney = false;

  @override
  void initState() {
    super.initState();
  }

  void _addCustomTag(String text) {
    if (text.trim().isEmpty) return;
    final label = text.trim();
    if (_selectedTags.value.contains(label)) return;

    setState(() {
      _selectedTags.value = Set.from(_selectedTags.value)..add(label);
      final newTag = TagModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: label,
        iconCode: _getIconForInterest(label).codePoint,
      );
      _customTags.add(newTag);
      _searchController.clear();
    });
  }

  IconData _getIconForInterest(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('burger') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('coffee') || lower.contains('cafe')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('drink') || lower.contains('bar')) {
      return Icons.local_bar_rounded;
    }
    if (lower.contains('cloth') || lower.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('tech') || lower.contains('electr')) {
      return Icons.devices_other_rounded;
    }
    if (lower.contains('shop') || lower.contains('store')) {
      return Icons.shopping_bag_rounded;
    }
    if (lower.contains('gas') || lower.contains('petrol')) {
      return Icons.local_gas_station_rounded;
    }
    if (lower.contains('money') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('pharmacy') || lower.contains('med')) {
      return Icons.local_pharmacy_rounded;
    }
    return Icons.label_rounded;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor:
          theme.dialogTheme.backgroundColor ?? colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What are you looking for?',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.md),
            AppTextField.regular(
              controller: _searchController,
              hint: 'Enter interest (e.g. Pizza)',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colorScheme.primary,
                ),
                onPressed: () => _addCustomTag(_searchController.text),
              ),
              onSubmitted: _addCustomTag,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Popular Tags',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, textValue, _) {
                return ref.watch(tagsProvider).when(
                  data: (tags) {
                    final query = textValue.text.toLowerCase().trim();
                    var allChips = [...tags, ..._customTags];

                    if (query.isNotEmpty) {
                      allChips = allChips
                          .where((t) => t.name.toLowerCase().contains(query))
                          .toList();
                    }

                    return SizedBox(
                      height: 160,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: allChips.map((tag) {
                            return _TagChipWidget(
                              tag: tag,
                              selectedTags: _selectedTags,
                              onToggle: (_) {},
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                );
              },
            ),
            const SizedBox(height: AppDimensions.lg),
            ElevatedButton(
              onPressed: _isStartingJourney
                  ? null
                  : () async {
                      if (_isStartingJourney) {
                        return;
                      }

                      setState(() {
                        _isStartingJourney = true;
                      });

                      final query = _searchController.text.trim();
                      final locationNotifier = ref.read(
                        currentLocationProvider.notifier,
                      );
                      var locationState = ref.read(currentLocationProvider);
                      LatLng? latLng = locationState.position != null
                          ? LatLng(
                              locationState.position!.latitude,
                              locationState.position!.longitude,
                            )
                          : null;
                      final navigator = Navigator.of(context);
                      final router = GoRouter.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.maybeOf(
                        context,
                      );

                      try {
                        await ref
                            .read(navigationControllerProvider.notifier)
                            .restoreActiveJourneyState(forceSync: true);

                        if (!mounted) return;

                        if (ref
                            .read(navigationControllerProvider)
                            .hasActiveJourney) {
                          if (scaffoldMessenger != null) {
                            AppSnackbar.showWithScaffoldMessenger(
                              scaffoldMessenger,
                              message:
                                  'Complete your active journey before starting a new one.',
                              type: AppSnackbarType.warning,
                            );
                          }
                          if (navigator.mounted) {
                            navigator.pop();
                          }
                          router.go(AppRoutes.navigate);
                          return;
                        }

                        if (latLng == null) {
                          await locationNotifier.fetchCurrentLocation(
                            requestPermission: true,
                            resolvePlaceName: false,
                            forceRefresh: true,
                          );
                          locationState = ref.read(currentLocationProvider);
                          final currentPos = locationState.position;
                          if (currentPos != null) {
                            latLng = LatLng(
                              currentPos.latitude,
                              currentPos.longitude,
                            );
                          }
                        }

                        if (latLng == null) {
                          if (scaffoldMessenger != null) {
                            AppSnackbar.showWithScaffoldMessenger(
                              scaffoldMessenger,
                              message:
                                  locationState.errorMessage ??
                                  'Turn on location access to start exploring nearby.',
                              type: AppSnackbarType.warning,
                            );
                          }
                          return;
                        }

                        final started = await ref
                            .read(navigationControllerProvider.notifier)
                            .startFreeRoam(
                              interests: _selectedTags.value.toList(),
                              query: query.isEmpty ? null : query,
                              currentPosition: latLng,
                            );

                        if (!mounted) return;

                        if (!started) {
                          final message =
                              ref
                                  .read(navigationControllerProvider)
                                  .errorMessage ??
                              'Unable to start exploring right now. Please try again.';
                          if (scaffoldMessenger != null) {
                            AppSnackbar.showWithScaffoldMessenger(
                              scaffoldMessenger,
                              message: message,
                              type: AppSnackbarType.error,
                            );
                          }
                          return;
                        }

                        if (navigator.mounted) {
                          navigator.pop();
                        }
                        router.go(AppRoutes.navigate);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isStartingJourney = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: _isStartingJourney
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Start Exploring',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChipWidget extends StatelessWidget {
  final TagModel tag;
  final ValueNotifier<Set<String>> selectedTags;
  final Function(String) onToggle;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TagChipWidget({
    required this.tag,
    required this.selectedTags,
    required this.onToggle,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedTags,
      builder: (context, selected, _) {
        final isSelected = selected.contains(tag.name);
        return GestureDetector(
          onTap: () {
            final newSet = Set<String>.from(selected);
            if (newSet.contains(tag.name)) {
              newSet.remove(tag.name);
            } else {
              newSet.add(tag.name);
            }
            selectedTags.value = newSet;
            onToggle(tag.name);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tag.icon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  tag.name,
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
