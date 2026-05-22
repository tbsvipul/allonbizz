import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:allonbiz_mobile/core/models/discovery_model.dart';
import 'package:allonbiz_mobile/core/network/api_client.dart';
import 'package:allonbiz_mobile/core/services/current_location_provider.dart';
import 'package:allonbiz_mobile/core/services/discovery_service.dart';
import 'package:allonbiz_mobile/core/services/location_service.dart';
import 'package:allonbiz_mobile/core/services/storage_service.dart';
import 'package:allonbiz_mobile/features/discover/data/repositories/deals_repository.dart';
import 'package:allonbiz_mobile/features/home/data/repositories/home_repository.dart';
import 'package:allonbiz_mobile/shared/models/offer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SWR providers', () {
    test(
      'categoriesProvider emits cached data first and then fresh data',
      () async {
        final service = _FakeDiscoveryService(
          categoryStream: Stream<List<CategoryModel>>.fromIterable([
            [
              CategoryModel(
                id: '1',
                label: 'Food',
                iconCode: 0xe51c,
                colorHex: '#FF0000',
              ),
            ],
            [
              CategoryModel(
                id: '1',
                label: 'Food',
                iconCode: 0xe51c,
                colorHex: '#FF0000',
              ),
              CategoryModel(
                id: '2',
                label: 'Cafe',
                iconCode: 0xe362,
                colorHex: '#00FF00',
              ),
            ],
          ]),
        );

        final container = ProviderContainer(
          overrides: [discoveryServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);

        final emissions = await _collectDataEmissions(
          container,
          categoriesProvider,
          expectedCount: 2,
        );

        expect(
          emissions
              .map((items) => items.map((item) => item.label).toList())
              .toList(),
          [
            ['Food'],
            ['Food', 'Cafe'],
          ],
        );
      },
    );

    test('tagsProvider emits cached data first and then fresh data', () async {
      final service = _FakeDiscoveryService(
        tagStream: Stream<List<TagModel>>.fromIterable([
          [TagModel(id: '1', name: 'Coffee', iconCode: 0xe362)],
          [
            TagModel(id: '1', name: 'Coffee', iconCode: 0xe362),
            TagModel(id: '2', name: 'Breakfast', iconCode: 0xeb48),
          ],
        ]),
      );

      final container = ProviderContainer(
        overrides: [discoveryServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final emissions = await _collectDataEmissions(
        container,
        tagsProvider,
        expectedCount: 2,
      );

      expect(
        emissions
            .map((items) => items.map((item) => item.name).toList())
            .toList(),
        [
          ['Coffee'],
          ['Coffee', 'Breakfast'],
        ],
      );
    });

    test(
      'dealsProvider uses the current location and emits cached then fresh offers',
      () async {
        final repo = _FakeDealsRepository(
          streamFactory:
              ({
                double? lat,
                double? lng,
                double? radiusKm,
                String? category,
                List<String> tags = const [],
              }) {
                return Stream<List<Offer>>.fromIterable([
                  [_offer(id: '1', title: 'Cached Deal')],
                  [_offer(id: '1', title: 'Fresh Deal')],
                ]);
              },
        );

        final position = _position(latitude: 23.0225, longitude: 72.5714);
        final container = ProviderContainer(
          overrides: [
            dealsRepositoryProvider.overrideWithValue(repo),
            currentLocationProvider.overrideWith((ref) {
              final notifier = CurrentLocationNotifier(
                _FakeLocationService(),
                ref,
              );
              notifier.state = CurrentLocationState(position: position);
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final emissions = await _collectDataEmissions(
          container,
          dealsProvider,
          expectedCount: 2,
        );

        expect(repo.lastLat, position.latitude);
        expect(repo.lastLng, position.longitude);
        expect(emissions.map((items) => items.single.title).toList(), [
          'Cached Deal',
          'Fresh Deal',
        ]);
      },
    );

    test(
      'homeOffersProvider uses recommended offers when location is unavailable',
      () async {
        final repo = _FakeHomeRepository(
          recommendedStream: Stream<List<Offer>>.fromIterable([
            [_offer(id: '1', title: 'Cached Home Deal')],
            [_offer(id: '1', title: 'Fresh Home Deal')],
          ]),
        );

        final container = ProviderContainer(
          overrides: [
            homeRepositoryProvider.overrideWithValue(repo),
            currentLocationProvider.overrideWith((ref) {
              final notifier = CurrentLocationNotifier(
                _FakeLocationService(),
                ref,
              );
              notifier.state = const CurrentLocationState(
                position: null,
                isLoading: false,
              );
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final emissions = await _collectDataEmissions(
          container,
          homeOffersProvider,
          expectedCount: 2,
        );

        expect(repo.recommendedCalls, 1);
        expect(repo.nearbyCalls, 0);
        expect(emissions.map((items) => items.single.title).toList(), [
          'Cached Home Deal',
          'Fresh Home Deal',
        ]);
      },
    );

    test(
      'homeOffersProvider uses nearby offers when location is available',
      () async {
        final repo = _FakeHomeRepository(
          nearbyStream: Stream<List<Offer>>.fromIterable([
            [_offer(id: '1', title: 'Cached Nearby Deal')],
            [_offer(id: '1', title: 'Fresh Nearby Deal')],
          ]),
        );

        final position = _position(latitude: 19.0760, longitude: 72.8777);
        final container = ProviderContainer(
          overrides: [
            homeRepositoryProvider.overrideWithValue(repo),
            currentLocationProvider.overrideWith((ref) {
              final notifier = CurrentLocationNotifier(
                _FakeLocationService(),
                ref,
              );
              notifier.state = CurrentLocationState(position: position);
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final emissions = await _collectDataEmissions(
          container,
          homeOffersProvider,
          expectedCount: 2,
        );

        expect(repo.recommendedCalls, 0);
        expect(repo.nearbyCalls, 1);
        expect(repo.lastLat, position.latitude);
        expect(repo.lastLng, position.longitude);
        expect(emissions.map((items) => items.single.title).toList(), [
          'Cached Nearby Deal',
          'Fresh Nearby Deal',
        ]);
      },
    );

    test(
      'featuredDealsProvider uses recommended offers when location is unavailable',
      () async {
        final dealsRepo = _FakeDealsRepository(
          streamFactory:
              ({
                double? lat,
                double? lng,
                double? radiusKm,
                String? category,
                List<String> tags = const [],
              }) {
                return Stream<List<Offer>>.fromIterable([
                  [_offer(id: '1', title: 'Nearby Deal')],
                ]);
              },
        );
        final homeRepo = _FakeHomeRepository(
          recommendedStream: Stream<List<Offer>>.fromIterable([
            [_offer(id: '1', title: 'Cached Featured Deal')],
            [_offer(id: '1', title: 'Fresh Featured Deal')],
          ]),
        );

        final container = ProviderContainer(
          overrides: [
            dealsRepositoryProvider.overrideWithValue(dealsRepo),
            homeRepositoryProvider.overrideWithValue(homeRepo),
            currentLocationProvider.overrideWith((ref) {
              final notifier = CurrentLocationNotifier(
                _FakeLocationService(),
                ref,
              );
              notifier.state = const CurrentLocationState(
                position: null,
                isLoading: false,
              );
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final emissions = await _collectDataEmissions(
          container,
          featuredDealsProvider,
          expectedCount: 2,
        );

        expect(homeRepo.recommendedCalls, 1);
        expect(dealsRepo.watchOffersCalls, 0);
        expect(dealsRepo.lastLat, isNull);
        expect(dealsRepo.lastLng, isNull);
        expect(emissions.map((items) => items.single.title).toList(), [
          'Cached Featured Deal',
          'Fresh Featured Deal',
        ]);
      },
    );
  });
}

class _FakeDiscoveryService extends DiscoveryService {
  _FakeDiscoveryService({
    Stream<List<CategoryModel>>? categoryStream,
    Stream<List<TagModel>>? tagStream,
  }) : _categoryStream = categoryStream ?? const Stream.empty(),
       _tagStream = tagStream ?? const Stream.empty(),
       super(apiClient: _dummyApiClient());

  final Stream<List<CategoryModel>> _categoryStream;
  final Stream<List<TagModel>> _tagStream;

  @override
  Stream<List<CategoryModel>> watchCategories() => _categoryStream;

  @override
  Stream<List<TagModel>> watchTags() => _tagStream;
}

class _FakeDealsRepository extends DealsRepository {
  _FakeDealsRepository({
    required Stream<List<Offer>> Function({
      double? lat,
      double? lng,
      double? radiusKm,
      String? category,
      List<String> tags,
    })
    streamFactory,
  }) : _streamFactory = streamFactory,
       super(apiClient: _dummyApiClient());

  final Stream<List<Offer>> Function({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags,
  })
  _streamFactory;

  int watchOffersCalls = 0;
  double? lastLat;
  double? lastLng;

  @override
  Stream<List<Offer>> watchOffers({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags = const [],
  }) {
    watchOffersCalls += 1;
    lastLat = lat;
    lastLng = lng;
    return _streamFactory(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      category: category,
      tags: tags,
    );
  }
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository({
    Stream<List<Offer>>? recommendedStream,
    Stream<List<Offer>>? nearbyStream,
  }) : _recommendedStream = recommendedStream ?? const Stream.empty(),
       _nearbyStream = nearbyStream ?? const Stream.empty(),
       super(apiClient: _dummyApiClient());

  final Stream<List<Offer>> _recommendedStream;
  final Stream<List<Offer>> _nearbyStream;

  int recommendedCalls = 0;
  int nearbyCalls = 0;
  double? lastLat;
  double? lastLng;

  @override
  Stream<List<Offer>> watchRecommendedOffers() {
    recommendedCalls += 1;
    return _recommendedStream;
  }

  @override
  Stream<List<Offer>> watchNearbyOffers(double lat, double lng) {
    nearbyCalls += 1;
    lastLat = lat;
    lastLng = lng;
    return _nearbyStream;
  }
}

class _FakeLocationService extends LocationService {}

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('HTTP should not be called in provider tests.');
  }
}

ApiClient _dummyApiClient() {
  return ApiClient(
    baseUrl: 'https://example.com',
    storageService: StorageService(),
    client: _NoopHttpClient(),
  );
}

Offer _offer({required String id, required String title}) {
  return Offer(
    id: id,
    title: title,
    description: 'Description',
    category: 'food',
    discountPercent: 10,
    latitude: 23.0225,
    longitude: 72.5714,
    createdAt: DateTime(2024),
  );
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

Future<List<T>> _collectDataEmissions<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider, {
  required int expectedCount,
}) async {
  final values = <T>[];
  final completer = Completer<List<T>>();

  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = container.listen<AsyncValue<T>>(provider, (previous, next) {
    next.whenData((value) {
      values.add(value);
      if (values.length >= expectedCount && !completer.isCompleted) {
        completer.complete(List<T>.unmodifiable(values));
        subscription.close();
      }
    });
  }, fireImmediately: true);

  return completer.future.timeout(const Duration(seconds: 5));
}
