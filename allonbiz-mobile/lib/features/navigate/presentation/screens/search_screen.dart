import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/discovery_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/search_controller.dart';
import '../widgets/search_input_fields.dart';
import '../widgets/search_interest_tags.dart';
import '../widgets/search_suggestions_list.dart';

/// Search destination screen with integrated interests and route planning.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _originController;
  late final TextEditingController _searchController;
  late final TextEditingController _interestSearchController;
  late final FocusNode _originFocus;
  late final FocusNode _searchFocus;
  late final FocusNode _interestFocus;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController();
    _searchController = TextEditingController();
    _interestSearchController = TextEditingController();
    _originFocus = FocusNode();
    _searchFocus = FocusNode();
    _interestFocus = FocusNode();
    _originFocus.addListener(_handleFocusChange);
    _searchFocus.addListener(_handleFocusChange);
    _interestFocus.addListener(_handleFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();

      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        unawaited(
          ref
              .read(currentLocationProvider.notifier)
              .fetchCurrentLocation(
                requestPermission: false,
                resolvePlaceName: false,
              ),
        );
      }
    });
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
    if (!_originFocus.hasFocus && !_searchFocus.hasFocus) {
      ref.read(searchControllerProvider.notifier).clearSuggestions();
    }
  }

  Future<CustomInterestAddStatus> _addCustomInterest(String text) async {
    final status = await ref
        .read(searchControllerProvider.notifier)
        .addCustomInterest(text);
    if (status == CustomInterestAddStatus.added) {
      _interestSearchController.clear();
    }
    return status;
  }

  void _showAllTagsDialog() {
    final popupSearchController = TextEditingController();
    final popupFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Consumer(
          builder: (context, ref, _) {
            final searchState = ref.watch(searchControllerProvider);
            final tagsAsync = ref.watch(tagsProvider);
            final tags = tagsAsync.valueOrNull ?? [];
            final allTags = [
              ...tags,
              ...searchState.customInterests,
            ];
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add your interests',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SearchInterestTags(
                      tags: allTags,
                      selectedInterests: searchState.selectedInterests,
                      interestSearchController: popupSearchController,
                      interestFocus: popupFocusNode,
                      isAddingTag: searchState.isAddingCustomInterest,
                      onAddCustomInterest: _addCustomInterest,
                      onToggleInterest: (name) => ref
                          .read(searchControllerProvider.notifier)
                          .toggleInterest(name),
                      isDark: isDark,
                      height: MediaQuery.of(context).size.height * 0.55,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      popupSearchController.dispose();
      popupFocusNode.dispose();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _searchController.dispose();
    _interestSearchController.dispose();
    _originFocus.dispose();
    _searchFocus.dispose();
    _interestFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSearchSubmitted(
    String value, {
    required SearchInputField field,
  }) async {
    if (value.trim().length < 2) return;
    await ref
        .read(searchControllerProvider.notifier)
        .searchImmediately(value.trim(), field: field, autoSelectFirst: true);
    _syncSelectedTextFields();
  }

  void _selectSuggestion(
    PlaceSuggestion suggestion, {
    required SearchInputField field,
  }) {
    ref
        .read(searchControllerProvider.notifier)
        .selectSuggestion(suggestion, field: field);
    _syncSelectedTextFields();
    if (field == SearchInputField.origin) {
      _searchFocus.requestFocus();
    } else {
      _interestFocus.requestFocus();
    }
  }

  Future<bool> _resolvePendingSelection({required bool isOrigin}) async {
    final controller = isOrigin ? _originController : _searchController;
    final resolved = await ref
        .read(searchControllerProvider.notifier)
        .resolvePendingSelection(
          controller.text,
          field: isOrigin
              ? SearchInputField.origin
              : SearchInputField.destination,
        );
    if (resolved) {
      _syncSelectedTextFields();
    }
    return resolved;
  }

  Future<void> _useCurrentLocationAsStartPoint() async {
    final l10n = AppLocalizations.of(context)!;
    final locationNotifier = ref.read(currentLocationProvider.notifier);
    var locationState = ref.read(currentLocationProvider);

    if (locationState.position == null) {
      await locationNotifier.fetchCurrentLocation(
        requestPermission: true,
        resolvePlaceName: false,
      );
      locationState = ref.read(currentLocationProvider);
    }

    if (!mounted) return;

    if (locationState.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationState.errorMessage ?? l10n.locationUnavailable),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Resolve address via reverse geocoding
    String label = locationState.placeName ?? l10n.currentLocation;
    try {
      final suggestion = await ref
          .read(placesServiceProvider)
          .reverseGeocode(
            locationState.position!.latitude,
            locationState.position!.longitude,
          );
      if (suggestion != null) {
        label = suggestion.name;
      }
    } catch (_) {}

    if (!mounted) return;

    ref
        .read(searchControllerProvider.notifier)
        .setOrigin(
          LatLng(
            locationState.position!.latitude,
            locationState.position!.longitude,
          ),
          label,
        );
    _originController.text = label;

    // Move focus to destination
    _searchFocus.requestFocus();
  }

  Future<void> _startJourney() async {
    final searchController = ref.read(searchControllerProvider.notifier);
    final currentSearchState = ref.read(searchControllerProvider);
    if (currentSearchState.isStartingJourney) return;

    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    searchController.setJourneyStarting(true);

    try {
      await ref
          .read(navigationControllerProvider.notifier)
          .restoreActiveJourneyState(forceSync: true);

      final hasActiveJourney = ref
          .read(navigationControllerProvider)
          .hasActiveJourney;

      if (hasActiveJourney) {
        if (!mounted) return;
        final shouldStartNew = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Active Journey Detected'),
            content: const Text(
              'You currently have an active journey. Do you want to end it and start a new journey?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('New Journey'),
              ),
            ],
          ),
        );

        if (shouldStartNew != true) {
          searchController.setJourneyStarting(false);
          return;
        }

        await ref.read(navigationControllerProvider.notifier).clearRoute();
      }

      final locationNotifier = ref.read(currentLocationProvider.notifier);
      var locationState = ref.read(currentLocationProvider);

      var searchState = ref.read(searchControllerProvider);

      if (_originController.text.trim().isNotEmpty &&
          searchState.selectedOrigin == null) {
        final resolvedOrigin = await _resolvePendingSelection(isOrigin: true);
        if (!resolvedOrigin && mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Select a valid starting location from suggestions.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        searchState = ref.read(searchControllerProvider);
      }

      final wantsDestination = _searchController.text.trim().isNotEmpty;
      if (wantsDestination && searchState.selectedDestination == null) {
        final resolvedDestination = await _resolvePendingSelection(
          isOrigin: false,
        );
        if (!resolvedDestination && mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Select a valid destination from suggestions to start navigation.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        searchState = ref.read(searchControllerProvider);
      }

      if (searchState.selectedOrigin == null &&
          locationState.position == null) {
        await locationNotifier.fetchCurrentLocation(
          requestPermission: true,
          resolvePlaceName: false,
        );
        locationState = ref.read(currentLocationProvider);
      }

      final origin =
          searchState.selectedOrigin ??
          (locationState.position != null
              ? LatLng(
                  locationState.position!.latitude,
                  locationState.position!.longitude,
                )
              : const LatLng(19.0760, 72.8777));

      if (!mounted) return;

      if (locationState.position == null &&
          searchState.selectedOrigin == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Live location was unavailable, so the route starts from default Location.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (searchState.selectedOriginLabel == null) {
          searchController.setOrigin(
            origin,
            locationState.placeName ?? l10n.currentLocation,
          );
          searchState = ref.read(searchControllerProvider);
          _syncSelectedTextFields();
        }
      }

      final interestQuery = _interestSearchController.text.trim();
      if (searchState.selectedDestination != null &&
          searchState.selectedDestinationName != null) {
        final started = await ref
            .read(navigationControllerProvider.notifier)
            .setDestination(
              origin,
              searchState.selectedDestination!,
              searchState.selectedDestinationName!,
              startName: searchState.selectedOriginLabel,
              interests: searchState.selectedInterests,
              interestQuery: interestQuery.isEmpty ? null : interestQuery,
            );
        if (!started) {
          return;
        }
      } else {
        final started = await ref
            .read(navigationControllerProvider.notifier)
            .startFreeRoam(
              interests: searchState.selectedInterests,
              query: interestQuery.isEmpty ? null : interestQuery,
              currentPosition: origin,
            );
        if (!started) {
          return;
        }
      }

      if (!mounted) return;
      router.go(AppRoutes.navigate);
    } finally {
      searchController.setJourneyStarting(false);
    }
  }

  void _syncSelectedTextFields() {
    final searchState = ref.read(searchControllerProvider);
    final originLabel = searchState.selectedOriginLabel;
    if (originLabel != null && _originController.text != originLabel) {
      _originController.value = TextEditingValue(
        text: originLabel,
        selection: TextSelection.collapsed(offset: originLabel.length),
      );
    }

    final destinationLabel = searchState.selectedDestinationName;
    if (destinationLabel != null &&
        _searchController.text != destinationLabel) {
      _searchController.value = TextEditingValue(
        text: destinationLabel,
        selection: TextSelection.collapsed(offset: destinationLabel.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        safeArea: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Where to next?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan your journey with editorial precision.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // ── Input Section ───────────────────────────────────────────
                    const SizedBox(height: AppDimensions.md),
                    SearchInputFields(
                      originController: _originController,
                      destinationController: _searchController,
                      originFocus: _originFocus,
                      destinationFocus: _searchFocus,
                      onOriginChanged: (value) {
                        ref
                            .read(searchControllerProvider.notifier)
                            .handleQueryChanged(
                              value,
                              field: SearchInputField.origin,
                            );
                      },
                      onDestinationChanged: (value) {
                        ref
                            .read(searchControllerProvider.notifier)
                            .handleQueryChanged(
                              value,
                              field: SearchInputField.destination,
                            );
                      },
                      onOriginSubmitted: (v) => _handleSearchSubmitted(
                        v,
                        field: SearchInputField.origin,
                      ),
                      onDestinationSubmitted: (v) => _handleSearchSubmitted(
                        v,
                        field: SearchInputField.destination,
                      ),
                      onUseCurrentLocation: _useCurrentLocationAsStartPoint,
                      isDark: isDark,
                    ),

                    // Suggestions for active field
                    if (searchState.isLoading ||
                        searchState.suggestions.isNotEmpty)
                      SearchSuggestionsList(
                        suggestions: searchState.suggestions,
                        isLoading: searchState.isLoading,
                        isDark: isDark,
                        onSelect: (suggestion) => _selectSuggestion(
                          suggestion,
                          field: _originFocus.hasFocus
                              ? SearchInputField.origin
                              : SearchInputField.destination,
                        ),
                      )
                    else if (_searchFocus.hasFocus && searchState.searchHistory.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recent Searches',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SearchSuggestionsList(
                            suggestions: searchState.searchHistory,
                            isLoading: false,
                            isDark: isDark,
                            isHistory: true,
                            onSelect: (suggestion) => _selectSuggestion(
                              suggestion,
                              field: SearchInputField.destination,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppDimensions.xl),

                    // Interests Section
                    ref
                        .watch(tagsProvider)
                        .when(
                          data: (tags) {
                            final allTags = [
                              ...tags,
                              ...searchState.customInterests,
                            ];
                            return SearchInterestTags(
                              tags: allTags,
                              selectedInterests: searchState.selectedInterests,
                              interestSearchController:
                                  _interestSearchController,
                              interestFocus: _interestFocus,
                              isAddingTag: searchState.isAddingCustomInterest,
                              onAddCustomInterest: _addCustomInterest,
                              onToggleInterest: (name) => ref
                                  .read(searchControllerProvider.notifier)
                                  .toggleInterest(name),
                              onShowAllTags: _showAllTagsDialog,
                              isDark: isDark,
                              isCompact: true,
                            );
                          },
                          loading: () =>
                              const Center(child: AppLoader.inline()),
                          error: (e, _) => const SizedBox.shrink(),
                        ),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            ),
            GlassmorphicContainer(
              padding: const EdgeInsets.all(AppDimensions.lg),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: AppButton.primary(
                onPressed: searchState.isStartingJourney ? null : _startJourney,
                isLoading: searchState.isStartingJourney,
                icon: Icons.navigation_rounded,
                label: 'Start Journey',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
