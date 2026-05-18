import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/app_models.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/services/background_tracking_coordinator.dart';
import '../../core/services/local_alert_service.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/spatial_math.dart';
import '../profile/preferences_controller.dart';

class NavigationController extends ChangeNotifier {
  NavigationController({
    required AppRepository repository,
    required AppStorage storage,
    required PreferencesController preferencesController,
    required LocalAlertService localAlertService,
    required BackgroundTrackingCoordinator backgroundTrackingCoordinator,
  }) : _repository = repository,
       _storage = storage,
       _preferencesController = preferencesController,
       _localAlertService = localAlertService,
       _backgroundTrackingCoordinator = backgroundTrackingCoordinator;

  final AppRepository _repository;
  final AppStorage _storage;
  final PreferencesController _preferencesController;
  final LocalAlertService _localAlertService;
  final BackgroundTrackingCoordinator _backgroundTrackingCoordinator;

  bool _initialized = false;
  bool _busy = false;
  String? _statusMessage;
  GeoPoint? _currentLocation;
  String _currentLocationLabel = 'Current location';
  RoutePlan? _activeRoute;
  JourneySession? _activeJourney;
  List<OfferSummary> _visibleOffers = const [];
  List<String> _selectedTags = const [];
  StreamSubscription<Position>? _locationSubscription;

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get statusMessage => _statusMessage;
  GeoPoint? get currentLocation => _currentLocation;
  String get currentLocationLabel => _currentLocationLabel;
  RoutePlan? get activeRoute => _activeRoute;
  JourneySession? get activeJourney => _activeJourney;
  List<OfferSummary> get visibleOffers => _visibleOffers;
  List<String> get selectedTags => _selectedTags;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _activeJourney = _storage.readActiveJourney();
    _activeRoute = _storage.readCachedRoute();
    _visibleOffers = _storage.readCachedOffers();
    _currentLocation = _storage.readLastKnownLocation();
    _selectedTags = _activeJourney?.tags ?? const [];
    _initialized = true;
    notifyListeners();

    if (_activeJourney != null) {
      if (_currentLocation == null) {
        await refreshCurrentLocation();
      }
      await _ensureTracking();
      await _startBackgroundTrackingIfEnabled();
    }
  }

  Future<void> refreshCurrentLocation() async {
    final permission = await _ensureLocationPermission();
    if (!permission) {
      _statusMessage = 'Location permission is required to navigate.';
      notifyListeners();
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    _currentLocation = GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    await _storage.writeLastKnownLocation(_currentLocation);

    try {
      _currentLocationLabel = await _repository.reverseGeocode(
        _currentLocation!,
      );
    } catch (_) {
      _currentLocationLabel = 'Current location';
    }
    notifyListeners();
  }

  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  Future<void> startDestinationJourney({
    required PlaceSuggestion destination,
    required List<String> tags,
  }) async {
    if (_currentLocation == null) {
      await refreshCurrentLocation();
    }
    if (_currentLocation == null) {
      return;
    }

    await _runBusy(() async {
      final route = await _repository.buildRoute(
        origin: _currentLocation!,
        destination: destination.point,
      );
      final offers = await _repository.getNearbyOffers(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        radiusKm: _preferencesController.preferences.discoveryRadiusKm,
        tags: tags,
      );
      final filtered = await filterOffersAlongRoute(
        route.points,
        offers,
        _preferencesController.preferences.discoveryRadiusKm,
      );
      final journeyId = await _repository.startJourney(
        startName: _currentLocationLabel,
        startPoint: _currentLocation!,
        type: 'destination',
        tags: tags,
        destinationName: destination.address,
        destinationPoint: destination.point,
      );

      _activeRoute = route;
      _visibleOffers = filtered;
      _selectedTags = tags;
      _activeJourney = JourneySession(
        journeyId: journeyId,
        type: 'destination',
        status: 'active',
        startName: _currentLocationLabel,
        startPoint: _currentLocation!,
        destinationName: destination.address,
        destinationPoint: destination.point,
        startTime: DateTime.now(),
        tags: tags,
        pathPoints: [_currentLocation!],
      );

      await _storage.writeCachedRoute(route);
      await _storage.writeCachedOffers(filtered);
      await _storage.writeActiveJourney(_activeJourney);
      await _storage.clearNotifiedOfferIds();
      await _ensureTracking();
      await _startBackgroundTrackingIfEnabled();
      _statusMessage = 'Journey started toward ${destination.title}.';
    });
  }

  Future<void> startFreeRoam({required List<String> tags}) async {
    if (_currentLocation == null) {
      await refreshCurrentLocation();
    }
    if (_currentLocation == null) {
      return;
    }

    await _runBusy(() async {
      final offers = await _repository.getNearbyOffers(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        radiusKm: _preferencesController.preferences.discoveryRadiusKm,
        tags: tags,
      );

      final journeyId = await _repository.startJourney(
        startName: _currentLocationLabel,
        startPoint: _currentLocation!,
        type: 'freeRoam',
        tags: tags,
      );

      _activeRoute = null;
      _visibleOffers = offers;
      _selectedTags = tags;
      _activeJourney = JourneySession(
        journeyId: journeyId,
        type: 'freeRoam',
        status: 'active',
        startName: _currentLocationLabel,
        startPoint: _currentLocation!,
        startTime: DateTime.now(),
        tags: tags,
        pathPoints: [_currentLocation!],
      );

      await _storage.writeCachedRoute(null);
      await _storage.writeCachedOffers(offers);
      await _storage.writeActiveJourney(_activeJourney);
      await _storage.clearNotifiedOfferIds();
      await _ensureTracking();
      await _startBackgroundTrackingIfEnabled();
      _statusMessage = 'Exploration started.';
      await _notifyNewOffers(offers);
    });
  }

  Future<void> refreshOffers() async {
    if (_currentLocation == null) {
      return;
    }

    final offers = await _repository.getNearbyOffers(
      lat: _currentLocation!.latitude,
      lng: _currentLocation!.longitude,
      radiusKm: _preferencesController.preferences.discoveryRadiusKm,
      tags: _selectedTags,
    );

    if (_activeRoute != null) {
      _visibleOffers = await filterOffersAlongRoute(
        _activeRoute!.points,
        offers,
        _preferencesController.preferences.discoveryRadiusKm,
      );
    } else {
      _visibleOffers = offers;
    }

    await _storage.writeCachedOffers(_visibleOffers);
    notifyListeners();
    await _notifyNewOffers(_visibleOffers);
  }

  Future<void> endJourney() async {
    final journey = _activeJourney;
    final location = _currentLocation;
    if (journey == null || location == null) {
      return;
    }

    await _runBusy(() async {
      await _repository.endJourney(
        journeyId: journey.journeyId,
        endName: journey.destinationName ?? _currentLocationLabel,
        endPoint: location,
        distanceMeters: journey.distanceMeters,
        durationSeconds: journey.durationSeconds,
        shopsEncountered: journey.shopsEncountered,
      );
      await _backgroundTrackingCoordinator.stop();
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _activeJourney = null;
      _activeRoute = null;
      _visibleOffers = const [];
      _selectedTags = const [];
      _statusMessage = 'Journey completed.';
      await _storage.clearJourneyCache();
    });
  }

  Future<void> _ensureTracking() async {
    await _locationSubscription?.cancel();
    final permission = await _ensureLocationPermission();
    if (!permission) {
      return;
    }

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 25,
          ),
        ).listen((position) async {
          final nextPoint = GeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          final previousPoint = _currentLocation;
          _currentLocation = nextPoint;
          await _storage.writeLastKnownLocation(nextPoint);

          final journey = _activeJourney;
          if (journey != null) {
            final increment = previousPoint == null
                ? 0
                : distanceMeters(previousPoint, nextPoint);
            final pathPoints = [...journey.pathPoints, nextPoint];
            final updated = journey.copyWith(
              distanceMeters: journey.distanceMeters + increment,
              durationSeconds: DateTime.now()
                  .difference(journey.startTime)
                  .inSeconds,
              pathPoints: pathPoints,
            );
            _activeJourney = updated;
            await _storage.writeActiveJourney(updated);
            await _repository.updateJourneyProgress(
              journeyId: updated.journeyId,
              currentPoint: nextPoint,
              distanceMeters: updated.distanceMeters,
              durationSeconds: updated.durationSeconds,
              shopsEncountered: updated.shopsEncountered,
            );
            await refreshOffers();
          }

          notifyListeners();
        });
  }

  Future<void> _notifyNewOffers(List<OfferSummary> offers) async {
    if (!_preferencesController.preferences.notificationsEnabled) {
      return;
    }

    final seenIds = _storage.readNotifiedOfferIds();
    final unseen = offers
        .where((offer) => !seenIds.contains(offer.offerId))
        .toList();
    if (unseen.isEmpty) {
      return;
    }

    for (final offer in unseen.take(3)) {
      await _localAlertService.showOfferAlert(offer);
    }
    await _storage.writeNotifiedOfferIds([
      ...seenIds,
      ...unseen.map((offer) => offer.offerId),
    ]);
  }

  Future<void> _startBackgroundTrackingIfEnabled() async {
    if (_preferencesController.preferences.backgroundTrackingEnabled) {
      await _backgroundTrackingCoordinator.start();
    }
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
