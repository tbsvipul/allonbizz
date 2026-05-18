import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

final searchOptionsProvider =
    FutureProvider<({List<CategorySummary> categories, List<TagItem> tags})>((
      ref,
    ) async {
      final repo = ref.read(appRepositoryProvider);
      final categories = await repo.getCategories();
      final tags = await repo.getPublicTags();
      return (categories: categories, tags: tags);
    });

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _destinationController = TextEditingController();
  final _tagInputController = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  PlaceSuggestion? _selectedDestination;
  final List<String> _tags = [];
  String _originLabel = 'Current location';
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await ref.read(navigationControllerProvider).initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _originLabel = ref.read(navigationControllerProvider).currentLocationLabel;
      });
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _tagInputController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationControllerProvider);
    final options = ref.watch(searchOptionsProvider);
    final theme = Theme.of(context);

    if (_originLabel != nav.currentLocationLabel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _originLabel = nav.currentLocationLabel;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plan a journey')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Origin',
              prefixIcon: const Icon(Icons.my_location_rounded),
              suffixIcon: IconButton(
                onPressed: () async {
                  await ref
                      .read(navigationControllerProvider)
                      .refreshCurrentLocation();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _originLabel = ref
                        .read(navigationControllerProvider)
                        .currentLocationLabel;
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            child: Text(
              _originLabel,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () async {
                final requestId = ++_searchRequestId;
                try {
                  final results = await ref
                      .read(appRepositoryProvider)
                      .searchPlaces(value);
                  if (mounted && requestId == _searchRequestId) {
                    setState(() {
                      _suggestions = results;
                    });
                  }
                } catch (_) {
                  if (mounted && requestId == _searchRequestId) {
                    setState(() {
                      _suggestions = const [];
                    });
                  }
                }
              });
            },
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _suggestions
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(item.title),
                        subtitle: Text(item.address),
                        onTap: () {
                          setState(() {
                            _selectedDestination = item;
                            _destinationController.text = item.address;
                            _suggestions = const [];
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          options.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Failed to load filters: $error'),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular tags',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...data.tags
                        .take(12)
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag.name),
                            selected: _tags.contains(tag.name),
                            onSelected: (_) => _toggleTag(tag.name),
                          ),
                        ),
                    ...data.categories
                        .take(6)
                        .map(
                          (category) => FilterChip(
                            label: Text(category.name),
                            selected: _tags.contains(category.name),
                            onSelected: (_) => _toggleTag(category.name),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _tagInputController,
            decoration: InputDecoration(
              labelText: 'What are you looking for?',
              prefixIcon: const Icon(Icons.sell_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  final value = _tagInputController.text.trim();
                  if (value.isEmpty) {
                    return;
                  }
                  _toggleTag(value);
                  _tagInputController.clear();
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isEmpty) {
                return;
              }
              _toggleTag(value.trim());
              _tagInputController.clear();
            },
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      avatar: Icon(_iconForTag(tag), size: 18),
                      onDeleted: () => _toggleTag(tag),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedDestination == null ? null : _startJourney,
              child: const Text('Start Journey'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _startExploration,
              child: const Text('Start Exploration'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTag(String value) {
    setState(() {
      if (_tags.contains(value)) {
        _tags.remove(value);
      } else {
        _tags.add(value);
      }
    });
    ref.read(navigationControllerProvider).setSelectedTags(_tags);
  }

  Future<void> _startJourney() async {
    if (_selectedDestination == null) {
      return;
    }

    await ref
        .read(navigationControllerProvider)
        .startDestinationJourney(
          destination: _selectedDestination!,
          tags: _tags,
        );
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _startExploration() async {
    await ref.read(navigationControllerProvider).startFreeRoam(tags: _tags);
    if (mounted) {
      context.pop();
    }
  }
}

IconData _iconForTag(String tag) {
  final normalized = tag.toLowerCase();
  if (normalized.contains('food') || normalized.contains('eat')) {
    return Icons.restaurant_outlined;
  }
  if (normalized.contains('fuel') || normalized.contains('petrol')) {
    return Icons.local_gas_station_outlined;
  }
  if (normalized.contains('atm') || normalized.contains('bank')) {
    return Icons.account_balance_outlined;
  }
  if (normalized.contains('coffee')) {
    return Icons.coffee_outlined;
  }
  return Icons.interests_outlined;
}
