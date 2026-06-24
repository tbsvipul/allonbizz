import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/models/discovery_model.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/services/storage_service.dart';
import '../utils/interest_tag_utils.dart';

enum SearchInputField { origin, destination }

enum CustomInterestAddStatus { empty, duplicate, added, failed }

class SearchViewState {
  const SearchViewState({
    this.suggestions = const <PlaceSuggestion>[],
    this.searchHistory = const <PlaceSuggestion>[],
    this.isLoading = false,
    this.isStartingJourney = false,
    this.isAddingCustomInterest = false,
    this.selectedInterests = const <String>[],
    this.customInterests = const <TagModel>[],
    this.selectedOrigin,
    this.selectedOriginLabel,
    this.selectedDestination,
    this.selectedDestinationName,
  });

  final List<PlaceSuggestion> suggestions;
  final List<PlaceSuggestion> searchHistory;
  final bool isLoading;
  final bool isStartingJourney;
  final bool isAddingCustomInterest;
  final List<String> selectedInterests;
  final List<TagModel> customInterests;
  final LatLng? selectedOrigin;
  final String? selectedOriginLabel;
  final LatLng? selectedDestination;
  final String? selectedDestinationName;

  SearchViewState copyWith({
    List<PlaceSuggestion>? suggestions,
    List<PlaceSuggestion>? searchHistory,
    bool? isLoading,
    bool? isStartingJourney,
    bool? isAddingCustomInterest,
    List<String>? selectedInterests,
    List<TagModel>? customInterests,
    Object? selectedOrigin = _unset,
    Object? selectedOriginLabel = _unset,
    Object? selectedDestination = _unset,
    Object? selectedDestinationName = _unset,
  }) {
    return SearchViewState(
      suggestions: suggestions ?? this.suggestions,
      searchHistory: searchHistory ?? this.searchHistory,
      isLoading: isLoading ?? this.isLoading,
      isStartingJourney: isStartingJourney ?? this.isStartingJourney,
      isAddingCustomInterest:
          isAddingCustomInterest ?? this.isAddingCustomInterest,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      customInterests: customInterests ?? this.customInterests,
      selectedOrigin: identical(selectedOrigin, _unset)
          ? this.selectedOrigin
          : selectedOrigin as LatLng?,
      selectedOriginLabel: identical(selectedOriginLabel, _unset)
          ? this.selectedOriginLabel
          : selectedOriginLabel as String?,
      selectedDestination: identical(selectedDestination, _unset)
          ? this.selectedDestination
          : selectedDestination as LatLng?,
      selectedDestinationName: identical(selectedDestinationName, _unset)
          ? this.selectedDestinationName
          : selectedDestinationName as String?,
    );
  }

  static const Object _unset = Object();
}

class SearchController extends StateNotifier<SearchViewState> {
  SearchController({
    required PlacesService placesService,
    required DiscoveryService discoveryService,
    required StorageService storageService,
  }) : _placesService = placesService,
       _discoveryService = discoveryService,
       _storageService = storageService,
       super(SearchViewState(
         searchHistory: storageService.searchHistory
             .map((e) => PlaceSuggestion.fromJson(e))
             .toList(),
       ));

  final PlacesService _placesService;
  final DiscoveryService _discoveryService;
  final StorageService _storageService;

  Timer? _debounce;
  int _requestSequence = 0;
  String _originQuery = '';
  String _destinationQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setJourneyStarting(bool isStartingJourney) {
    state = state.copyWith(isStartingJourney: isStartingJourney);
  }

  void clearSuggestions() {
    if (state.suggestions.isEmpty) {
      return;
    }
    state = state.copyWith(suggestions: const <PlaceSuggestion>[]);
  }

  void handleQueryChanged(String value, {required SearchInputField field}) {
    final trimmed = value.trim();
    _debounce?.cancel();

    if (field == SearchInputField.origin) {
      _originQuery = trimmed;
      if (state.selectedOriginLabel != null &&
          trimmed != state.selectedOriginLabel) {
        state = state.copyWith(selectedOrigin: null, selectedOriginLabel: null);
      }
    } else {
      _destinationQuery = trimmed;
      if (state.selectedDestinationName != null &&
          trimmed != state.selectedDestinationName) {
        state = state.copyWith(
          selectedDestination: null,
          selectedDestinationName: null,
        );
      }
    }

    if (trimmed.length < 2) {
      clearSuggestions();
      state = state.copyWith(isLoading: false);
      return;
    }

    _debounce = Timer(AppDurations.debounce, () {
      searchImmediately(trimmed, field: field);
    });
  }

  Future<void> searchImmediately(
    String value, {
    required SearchInputField field,
    bool autoSelectFirst = false,
  }) async {
    final query = value.trim();
    if (query.length < 2) {
      clearSuggestions();
      return;
    }

    if (field == SearchInputField.origin) {
      _originQuery = query;
    } else {
      _destinationQuery = query;
    }

    final requestId = ++_requestSequence;
    state = state.copyWith(isLoading: true);

    try {
      final suggestions = await _placesService.getAutocompleteSuggestions(
        query,
      );
      if (requestId != _requestSequence) {
        return;
      }

      final activeQuery = field == SearchInputField.origin
          ? _originQuery
          : _destinationQuery;
      if (activeQuery != query) {
        return;
      }

      if (autoSelectFirst && suggestions.isNotEmpty) {
        selectSuggestion(suggestions.first, field: field);
        return;
      }

      state = state.copyWith(suggestions: suggestions);
    } catch (_) {
      state = state.copyWith(suggestions: const <PlaceSuggestion>[]);
    } finally {
      if (requestId == _requestSequence) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void selectSuggestion(
    PlaceSuggestion suggestion, {
    required SearchInputField field,
  }) {
    _addToHistory(suggestion);
    if (field == SearchInputField.origin) {
      _originQuery = suggestion.name;
      state = state.copyWith(
        selectedOrigin: LatLng(suggestion.lat, suggestion.lon),
        selectedOriginLabel: suggestion.name,
        suggestions: const <PlaceSuggestion>[],
      );
      return;
    }

    _destinationQuery = suggestion.name;
    state = state.copyWith(
      selectedDestination: LatLng(suggestion.lat, suggestion.lon),
      selectedDestinationName: suggestion.name,
      suggestions: const <PlaceSuggestion>[],
    );
  }

  Future<bool> resolvePendingSelection(
    String value, {
    required SearchInputField field,
  }) async {
    final query = value.trim();
    if (query.isEmpty) {
      return true;
    }

    final hasMatchingSelection = field == SearchInputField.origin
        ? state.selectedOrigin != null && state.selectedOriginLabel == query
        : state.selectedDestination != null &&
              state.selectedDestinationName == query;
    if (hasMatchingSelection) {
      return true;
    }

    final suggestions = await _placesService.getAutocompleteSuggestions(query);
    if (suggestions.isEmpty) {
      return false;
    }

    selectSuggestion(_bestMatchingSuggestion(query, suggestions), field: field);
    return true;
  }

  Future<CustomInterestAddStatus> addCustomInterest(String value) async {
    final label = value.trim();
    if (label.isEmpty) {
      return CustomInterestAddStatus.empty;
    }
    if (state.selectedInterests.contains(label)) {
      return CustomInterestAddStatus.duplicate;
    }

    state = state.copyWith(
      isAddingCustomInterest: true,
      selectedInterests: [...state.selectedInterests, label],
      customInterests: [
        ...state.customInterests,
        buildCustomInterestTag(label),
      ],
    );

    try {
      final tag = await _discoveryService.addTag(label);
      if (tag != null) {
        final updatedCustomTags = [...state.customInterests]
          ..removeWhere((customTag) => customTag.name == label)
          ..add(tag);
        state = state.copyWith(customInterests: updatedCustomTags);
      }
      return CustomInterestAddStatus.added;
    } catch (_) {
      state = state.copyWith(
        selectedInterests: state.selectedInterests
            .where((interest) => interest != label)
            .toList(growable: false),
        customInterests: state.customInterests
            .where((customTag) => customTag.name != label)
            .toList(growable: false),
      );
      return CustomInterestAddStatus.failed;
    } finally {
      state = state.copyWith(isAddingCustomInterest: false);
    }
  }

  void toggleInterest(String name) {
    final updatedInterests = [...state.selectedInterests];
    if (updatedInterests.contains(name)) {
      updatedInterests.remove(name);
    } else {
      updatedInterests.add(name);
    }

    state = state.copyWith(selectedInterests: updatedInterests);
  }

  void setOrigin(LatLng point, String label) {
    _originQuery = label;
    state = state.copyWith(selectedOrigin: point, selectedOriginLabel: label);
  }

  void _addToHistory(PlaceSuggestion suggestion) {
    if (suggestion.isCurrentLocation) return;
    
    final currentHistory = [...state.searchHistory];
    currentHistory.removeWhere((e) => e.placeId == suggestion.placeId);
    currentHistory.insert(0, suggestion);
    if (currentHistory.length > 5) {
      currentHistory.removeLast();
    }
    
    _storageService.searchHistory = currentHistory.map((e) => e.toJson()).toList();
    
    state = state.copyWith(searchHistory: currentHistory);
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
}

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchViewState>((ref) {
      return SearchController(
        placesService: ref.watch(placesServiceProvider),
        discoveryService: ref.watch(discoveryServiceProvider),
        storageService: ref.watch(storageServiceProvider),
      );
    });
