import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/places_service.dart';
import 'package:locator/core/services/discovery_service.dart';
import 'package:locator/core/models/discovery_model.dart';
import '../controllers/navigation_controller.dart';
import 'package:locator/l10n/app_localizations.dart';
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

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _isLoading = false;
  bool _isStartingJourney = false;
  final List<String> _selectedInterests = [];
  final List<TagModel> _customInterests = [];

  LatLng? _selectedOrigin;
  String? _selectedOriginLabel;
  LatLng? _selectedDestination;
  String? _selectedDestinationName;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();

      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        ref.read(currentLocationProvider.notifier).fetchCurrentLocation();
      }
    });
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addCustomInterest(String text) {
    if (text.trim().isEmpty) return;
    final label = text.trim();
    if (_selectedInterests.contains(label)) return;

    if (mounted) {
      setState(() {
        _selectedInterests.add(label);
        final newTag = TagModel(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: label,
          iconCode: TagModel.guessIcon(label).codePoint,
        );

        _customInterests.add(newTag);
        _interestSearchController.clear();
      });
    }
  }

  void _showAllTagsDialog(List<TagModel> allTags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'What are you looking for?',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: allTags.map((tag) {
                        final isSelected = _selectedInterests.contains(
                          tag.name,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedInterests.remove(tag.name);
                              } else {
                                _selectedInterests.add(tag.name);
                              }
                            });
                            setModalState(() {});
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
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
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _originController.dispose();
    _searchController.dispose();
    _interestSearchController.dispose();
    _originFocus.dispose();
    _searchFocus.dispose();
    _interestFocus.dispose();
    super.dispose();
  }

  bool get _canStartJourney => !_isStartingJourney;

  void _handleOriginChanged(String value) {
    if (_selectedOriginLabel != null && value != _selectedOriginLabel) {
      setState(() {
        _selectedOrigin = null;
        _selectedOriginLabel = null;
      });
    }

    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _runSearch(value.trim(), isOrigin: true);
        }
      },
    );
  }

  void _handleSearchChanged(String value) {
    final trimmed = value.trim();

    if (_selectedDestinationName != null &&
        trimmed != _selectedDestinationName) {
      setState(() {
        _selectedDestination = null;
        _selectedDestinationName = null;
      });
    }

    _debounce?.cancel();

    if (trimmed.length < 2) {
      setState(() {
        _suggestions = const [];
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _runSearch(trimmed);
        }
      },
    );
  }

  Future<void> _runSearch(
    String query, {
    bool autoSelectFirst = false,
    bool isOrigin = false,
  }) async {
    if (!mounted || query.trim().isEmpty) return;

    final activeQuery = query.trim();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final suggestions = await ref
          .read(placesServiceProvider)
          .getAutocompleteSuggestions(query);

      if (!mounted) return;

      final currentText = isOrigin
          ? _originController.text
          : _searchController.text;
      if (currentText.trim() != activeQuery) return;

      if (autoSelectFirst && suggestions.isNotEmpty) {
        _selectSuggestion(suggestions.first, isOrigin: isOrigin);
        return;
      }

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (_) {
      // Quietly fail for autocomplete
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSearchSubmitted(
    String value, {
    bool isOrigin = false,
  }) async {
    if (value.trim().length < 2) return;
    await _runSearch(value.trim(), autoSelectFirst: true, isOrigin: isOrigin);
  }

  void _selectSuggestion(PlaceSuggestion suggestion, {bool isOrigin = false}) {
    if (mounted) {
      setState(() {
        if (isOrigin) {
          _selectedOrigin = LatLng(suggestion.lat, suggestion.lon);
          _selectedOriginLabel = suggestion.name;
          _originController.text = suggestion.name;
          _searchFocus.requestFocus();
        } else {
          _selectedDestination = LatLng(suggestion.lat, suggestion.lon);
          _selectedDestinationName = suggestion.name;
          _searchController.text = suggestion.name;
          _interestFocus.requestFocus();
        }
        _suggestions = const [];
      });
    }
  }

  Future<bool> _resolvePendingSelection({required bool isOrigin}) async {
    final controller = isOrigin ? _originController : _searchController;
    final selectedLabel = isOrigin
        ? _selectedOriginLabel
        : _selectedDestinationName;
    final selectedPoint = isOrigin ? _selectedOrigin : _selectedDestination;
    final query = controller.text.trim();

    if (query.isEmpty) {
      return true;
    }

    if (selectedPoint != null && selectedLabel == query) {
      return true;
    }

    final suggestions = await ref
        .read(placesServiceProvider)
        .getAutocompleteSuggestions(query);

    if (!mounted || suggestions.isEmpty) {
      return false;
    }

    _selectSuggestion(
      _bestMatchingSuggestion(query, suggestions),
      isOrigin: isOrigin,
    );
    return true;
  }

  PlaceSuggestion _bestMatchingSuggestion(
    String query,
    List<PlaceSuggestion> suggestions,
  ) {
    final normalized = query.trim().toLowerCase();
    for (final suggestion in suggestions) {
      if (suggestion.name.toLowerCase() == normalized) {
        return suggestion;
      }
    }
    for (final suggestion in suggestions) {
      final haystack = '${suggestion.name} ${suggestion.description}'
          .toLowerCase();
      if (haystack.contains(normalized)) {
        return suggestion;
      }
    }
    return suggestions.first;
  }

  Future<void> _useCurrentLocationAsStartPoint() async {
    final l10n = AppLocalizations.of(context)!;
    final locationNotifier = ref.read(currentLocationProvider.notifier);
    var locationState = ref.read(currentLocationProvider);

    if (locationState.position == null) {
      await locationNotifier.fetchCurrentLocation();
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

    if (mounted) {
      setState(() {
        _selectedOrigin = LatLng(
          locationState.position!.latitude,
          locationState.position!.longitude,
        );
        _selectedOriginLabel = label;
        _originController.text = label;
      });
    }

    // Move focus to destination
    _searchFocus.requestFocus();
  }

  Future<void> _startJourney() async {
    if (!_canStartJourney || _isStartingJourney) return;

    if (mounted) {
      setState(() {
        _isStartingJourney = true;
      });
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      final locationNotifier = ref.read(currentLocationProvider.notifier);
      var locationState = ref.read(currentLocationProvider);

      if (_originController.text.trim().isNotEmpty && _selectedOrigin == null) {
        final resolvedOrigin = await _resolvePendingSelection(isOrigin: true);
        if (!resolvedOrigin && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Select a valid starting location from suggestions.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      final wantsDestination = _searchController.text.trim().isNotEmpty;
      if (wantsDestination && _selectedDestination == null) {
        final resolvedDestination = await _resolvePendingSelection(
          isOrigin: false,
        );
        if (!resolvedDestination && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Select a valid destination from suggestions to start navigation.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      if (_selectedOrigin == null && locationState.position == null) {
        await locationNotifier.fetchCurrentLocation();
        locationState = ref.read(currentLocationProvider);
      }

      final origin =
          _selectedOrigin ??
          (locationState.position != null
              ? LatLng(
                  locationState.position!.latitude,
                  locationState.position!.longitude,
                )
              : const LatLng(19.0760, 72.8777));

      if (!mounted) return;

      if (locationState.position == null && _selectedOrigin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Live location was unavailable, so the route starts from default Location.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _selectedOriginLabel ??=
            locationState.placeName ?? l10n.currentLocation;
      }

      final interestQuery = _interestSearchController.text.trim();
      if (_selectedDestination != null && _selectedDestinationName != null) {
        await ref
            .read(navigationControllerProvider.notifier)
            .setDestination(
              origin,
              _selectedDestination!,
              _selectedDestinationName!,
              startName: _selectedOriginLabel,
              interests: _selectedInterests,
              interestQuery: interestQuery.isEmpty ? null : interestQuery,
            );
      } else {
        await ref
            .read(navigationControllerProvider.notifier)
            .startFreeRoam(
              interests: _selectedInterests,
              query: interestQuery.isEmpty ? null : interestQuery,
              currentPosition: origin,
            );
      }

      if (!mounted) return;
      context.go(AppRoutes.navigate);
    } finally {
      if (mounted) {
        setState(() {
          _isStartingJourney = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
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
                      onOriginChanged: _handleOriginChanged,
                      onDestinationChanged: _handleSearchChanged,
                      onOriginSubmitted:
                          (v) => _handleSearchSubmitted(v, isOrigin: true),
                      onDestinationSubmitted: (v) => _handleSearchSubmitted(v),
                      onUseCurrentLocation: _useCurrentLocationAsStartPoint,
                      isDark: isDark,
                    ),

                    // Suggestions for active field
                    if (_isLoading || _suggestions.isNotEmpty)
                      SearchSuggestionsList(
                        suggestions: _suggestions,
                        isLoading: _isLoading,
                        isDark: isDark,
                        onSelect: (s) => _selectSuggestion(
                          s,
                          isOrigin: _originFocus.hasFocus,
                        ),
                      ),

                    const SizedBox(height: AppDimensions.xl),

                    // Interests Section
                    ref
                        .watch(tagsProvider)
                        .when(
                          data: (tags) {
                            final allTags = [...tags, ..._customInterests];
                            return SearchInterestTags(
                              tags: allTags,
                              selectedInterests: _selectedInterests,
                              interestSearchController:
                                  _interestSearchController,
                              interestFocus: _interestFocus,
                              onAddCustomInterest: _addCustomInterest,
                              onToggleInterest: (name) {
                                if (mounted) {
                                  setState(() {
                                    if (_selectedInterests.contains(name)) {
                                      _selectedInterests.remove(name);
                                    } else {
                                      _selectedInterests.add(name);
                                    }
                                  });
                                }
                              },
                              onShowAllTags: () => _showAllTagsDialog(allTags),
                              isDark: isDark,
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => const SizedBox.shrink(),
                        ),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canStartJourney ? _startJourney : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    disabledBackgroundColor: colorScheme.primary.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: _isStartingJourney
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                          ),
                        )
                      : Text(
                          'Start Journey',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
