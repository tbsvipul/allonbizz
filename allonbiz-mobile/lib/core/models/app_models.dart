import 'dart:convert';

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }
  return const [];
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };

  factory AuthTokens.fromJson(Map<dynamic, dynamic> json) {
    return AuthTokens(
      accessToken: _asString(json['accessToken']),
      refreshToken: _asString(json['refreshToken']),
    );
  }
}

class SessionUser {
  const SessionUser({
    required this.userId,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePhotoUrl,
  });

  final String userId;
  final String email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String role;
  final String? profilePhotoUrl;

  String get displayName => '$firstName $lastName'.trim();

  SessionUser copyWith({
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? role,
    String? profilePhotoUrl,
  }) {
    return SessionUser(
      userId: userId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  factory SessionUser.fromJson(Map<dynamic, dynamic> json) {
    return SessionUser(
      userId: _asString(json['userId']),
      email: _asString(json['email']),
      phoneNumber: _asString(json['phoneNumber']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      role: _asString(json['role']),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'phoneNumber': phoneNumber,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'profilePhotoUrl': profilePhotoUrl,
  };
}

class UserPreferences {
  const UserPreferences({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.backgroundTrackingEnabled = true,
    this.discoveryRadiusKm = 2,
    this.language = 'en',
  });

  final bool darkMode;
  final bool notificationsEnabled;
  final bool backgroundTrackingEnabled;
  final double discoveryRadiusKm;
  final String language;

  UserPreferences copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? backgroundTrackingEnabled,
    double? discoveryRadiusKm,
    String? language,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundTrackingEnabled:
          backgroundTrackingEnabled ?? this.backgroundTrackingEnabled,
      discoveryRadiusKm: discoveryRadiusKm ?? this.discoveryRadiusKm,
      language: language ?? this.language,
    );
  }

  factory UserPreferences.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const UserPreferences();
    }

    return UserPreferences(
      darkMode: json['darkMode'] == true,
      notificationsEnabled: json['notificationsEnabled'] != false,
      backgroundTrackingEnabled: json['backgroundTrackingEnabled'] != false,
      discoveryRadiusKm: _asDouble(json['discoveryRadiusKm']) == 0
          ? 2
          : _asDouble(json['discoveryRadiusKm']),
      language: _asString(json['language']).isEmpty
          ? 'en'
          : _asString(json['language']),
    );
  }

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'backgroundTrackingEnabled': backgroundTrackingEnabled,
    'discoveryRadiusKm': discoveryRadiusKm,
    'language': language,
  };
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory GeoPoint.fromJson(Map<dynamic, dynamic> json) {
    return GeoPoint(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.title,
    required this.address,
    required this.point,
  });

  final String title;
  final String address;
  final GeoPoint point;

  factory PlaceSuggestion.fromPhoton(Map<dynamic, dynamic> json) {
    final geometry = json['geometry'] as Map<dynamic, dynamic>? ?? const {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];
    final properties = json['properties'] as Map<dynamic, dynamic>? ?? const {};
    final label = _asString(properties['name']).isNotEmpty
        ? _asString(properties['name'])
        : _asString(properties['label']);
    return PlaceSuggestion(
      title: label.isNotEmpty ? label : _asString(properties['label']),
      address: _asString(properties['label']),
      point: GeoPoint(
        latitude: coordinates.length > 1 ? _asDouble(coordinates[1]) : 0,
        longitude: coordinates.isNotEmpty ? _asDouble(coordinates[0]) : 0,
      ),
    );
  }

  factory PlaceSuggestion.fromApi(Map<dynamic, dynamic> json) {
    return PlaceSuggestion(
      title: _asString(json['name']).isNotEmpty
          ? _asString(json['name'])
          : _asString(json['title']),
      address: _asString(json['address']),
      point: GeoPoint(
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'address': address,
    'point': point.toJson(),
  };
}

class HomeSummary {
  const HomeSummary({
    this.totalTrips = 0,
    this.totalSaved = 0,
    this.loyaltyPoints = 0,
    this.hasActiveJourney = false,
    this.activeJourneyId,
    this.activeJourneyType,
    this.activeJourneyDestinationName,
  });

  final int totalTrips;
  final double totalSaved;
  final int loyaltyPoints;
  final bool hasActiveJourney;
  final String? activeJourneyId;
  final String? activeJourneyType;
  final String? activeJourneyDestinationName;

  factory HomeSummary.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const HomeSummary();
    }

    return HomeSummary(
      totalTrips: _asInt(json['totalTrips']),
      totalSaved: _asDouble(json['totalSaved']),
      loyaltyPoints: _asInt(json['loyaltyPoints']),
      hasActiveJourney: json['hasActiveJourney'] == true,
      activeJourneyId: json['activeJourneyId']?.toString(),
      activeJourneyType: json['activeJourneyType']?.toString(),
      activeJourneyDestinationName: json['activeJourneyDestinationName']
          ?.toString(),
    );
  }
}

class NearbyShop {
  const NearbyShop({
    required this.shopId,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.point,
    this.imageUrl,
  });

  final String shopId;
  final String name;
  final String address;
  final double distanceKm;
  final GeoPoint point;
  final String? imageUrl;

  factory NearbyShop.fromJson(Map<dynamic, dynamic> json) {
    return NearbyShop(
      shopId: _asString(json['shopId']),
      name: _asString(json['name']),
      address: _asString(json['address']),
      distanceKm: _asDouble(json['distanceKm']),
      point: GeoPoint(
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
      ),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class OfferSummary {
  const OfferSummary({
    required this.offerId,
    required this.shopId,
    required this.title,
    required this.shopName,
    required this.endDate,
    required this.tags,
    this.description,
    this.category,
    this.address,
    this.point,
    this.imageUrl,
    this.discountPercentage,
  });

  final String offerId;
  final String shopId;
  final String title;
  final String shopName;
  final String? description;
  final String? category;
  final String? address;
  final GeoPoint? point;
  final String? imageUrl;
  final double? discountPercentage;
  final DateTime endDate;
  final List<String> tags;

  factory OfferSummary.fromJson(Map<dynamic, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    return OfferSummary(
      offerId: _asString(json['offerId']),
      shopId: _asString(json['shopId']),
      title: _asString(json['title']),
      shopName: _asString(json['shopName']),
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      address: json['address']?.toString(),
      point: latitude == null && longitude == null
          ? null
          : GeoPoint(
              latitude: _asDouble(latitude),
              longitude: _asDouble(longitude),
            ),
      imageUrl: json['imageUrl']?.toString(),
      discountPercentage: json['discountPercentage'] == null
          ? null
          : _asDouble(json['discountPercentage']),
      endDate: DateTime.tryParse(_asString(json['endDate'])) ?? DateTime.now(),
      tags: _asStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
    'offerId': offerId,
    'shopId': shopId,
    'title': title,
    'shopName': shopName,
    'description': description,
    'category': category,
    'address': address,
    'latitude': point?.latitude,
    'longitude': point?.longitude,
    'imageUrl': imageUrl,
    'discountPercentage': discountPercentage,
    'endDate': endDate.toIso8601String(),
    'tags': tags,
  };
}

class CategorySummary {
  const CategorySummary({
    required this.categoryId,
    required this.name,
    this.icon,
    this.color,
  });

  final String categoryId;
  final String name;
  final String? icon;
  final String? color;

  factory CategorySummary.fromJson(Map<dynamic, dynamic> json) {
    return CategorySummary(
      categoryId: _asString(json['categoryId']),
      name: _asString(json['name']),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

class TagItem {
  const TagItem({
    required this.tagId,
    required this.name,
    this.color,
    this.iconData,
  });

  final String tagId;
  final String name;
  final String? color;
  final String? iconData;

  factory TagItem.fromJson(Map<dynamic, dynamic> json) {
    return TagItem(
      tagId: _asString(json['tagId']),
      name: _asString(json['name']),
      color: json['color']?.toString(),
      iconData: json['iconData']?.toString(),
    );
  }
}

class UserHomeData {
  const UserHomeData({
    required this.summary,
    required this.nearbyShops,
    required this.recommendedOffers,
    required this.categories,
  });

  final HomeSummary summary;
  final List<NearbyShop> nearbyShops;
  final List<OfferSummary> recommendedOffers;
  final List<CategorySummary> categories;

  factory UserHomeData.fromJson(Map<dynamic, dynamic> json) {
    return UserHomeData(
      summary: HomeSummary.fromJson(json['summary'] as Map<dynamic, dynamic>?),
      nearbyShops: (json['nearbyShops'] as List<dynamic>? ?? const [])
          .map((item) => NearbyShop.fromJson(item as Map<dynamic, dynamic>))
          .toList(),
      recommendedOffers:
          (json['recommendedOffers'] as List<dynamic>? ?? const [])
              .map(
                (item) => OfferSummary.fromJson(item as Map<dynamic, dynamic>),
              )
              .toList(),
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map(
            (item) => CategorySummary.fromJson(item as Map<dynamic, dynamic>),
          )
          .toList(),
    );
  }
}

class LoyaltySummary {
  const LoyaltySummary({
    required this.currentPoints,
    required this.tier,
    required this.pointsToNextTier,
  });

  final int currentPoints;
  final String tier;
  final int pointsToNextTier;

  factory LoyaltySummary.fromJson(Map<dynamic, dynamic> json) {
    return LoyaltySummary(
      currentPoints: _asInt(json['currentPoints']),
      tier: _asString(json['tier']),
      pointsToNextTier: _asInt(json['pointsToNextTier']),
    );
  }
}

class SavingsSummary {
  const SavingsSummary({
    required this.totalSaved,
    required this.totalRedemptions,
  });

  final double totalSaved;
  final int totalRedemptions;

  factory SavingsSummary.fromJson(Map<dynamic, dynamic> json) {
    return SavingsSummary(
      totalSaved: _asDouble(json['totalSaved']),
      totalRedemptions: _asInt(json['totalRedemptions']),
    );
  }
}

class RoutePlan {
  const RoutePlan({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.approximate,
  });

  final List<GeoPoint> points;
  final double distanceKm;
  final int durationMinutes;
  final bool approximate;

  factory RoutePlan.fromJson(Map<dynamic, dynamic> json) {
    return RoutePlan(
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((item) => GeoPoint.fromJson(item as Map<dynamic, dynamic>))
          .toList(),
      distanceKm: _asDouble(json['distanceKm']),
      durationMinutes: _asInt(json['durationMinutes']),
      approximate: json['approximate'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((item) => item.toJson()).toList(),
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
    'approximate': approximate,
  };
}

class JourneySession {
  const JourneySession({
    required this.journeyId,
    required this.type,
    required this.status,
    required this.startName,
    required this.startPoint,
    required this.startTime,
    required this.tags,
    required this.pathPoints,
    this.destinationName,
    this.destinationPoint,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.shopsEncountered = const [],
  });

  final String journeyId;
  final String type;
  final String status;
  final String startName;
  final GeoPoint startPoint;
  final String? destinationName;
  final GeoPoint? destinationPoint;
  final DateTime startTime;
  final double distanceMeters;
  final int durationSeconds;
  final List<String> tags;
  final List<String> shopsEncountered;
  final List<GeoPoint> pathPoints;

  JourneySession copyWith({
    String? status,
    double? distanceMeters,
    int? durationSeconds,
    List<String>? shopsEncountered,
    List<GeoPoint>? pathPoints,
  }) {
    return JourneySession(
      journeyId: journeyId,
      type: type,
      status: status ?? this.status,
      startName: startName,
      startPoint: startPoint,
      destinationName: destinationName,
      destinationPoint: destinationPoint,
      startTime: startTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      tags: tags,
      shopsEncountered: shopsEncountered ?? this.shopsEncountered,
      pathPoints: pathPoints ?? this.pathPoints,
    );
  }

  factory JourneySession.fromJson(Map<dynamic, dynamic> json) {
    return JourneySession(
      journeyId: _asString(json['journeyId']),
      type: _asString(json['type']).isEmpty
          ? 'freeRoam'
          : _asString(json['type']),
      status: _asString(json['status']).isEmpty
          ? 'active'
          : _asString(json['status']),
      startName: _asString(json['startName']),
      startPoint: GeoPoint(
        latitude: _asDouble(
          json['startLat'] ?? json['startPoint']?['latitude'],
        ),
        longitude: _asDouble(
          json['startLng'] ?? json['startPoint']?['longitude'],
        ),
      ),
      destinationName:
          json['destinationName']?.toString() ?? json['endName']?.toString(),
      destinationPoint:
          json['destLat'] == null &&
              json['destLng'] == null &&
              json['endLat'] == null &&
              json['endLng'] == null
          ? null
          : GeoPoint(
              latitude: _asDouble(json['destLat'] ?? json['endLat']),
              longitude: _asDouble(json['destLng'] ?? json['endLng']),
            ),
      startTime:
          DateTime.tryParse(_asString(json['startTime'])) ?? DateTime.now(),
      distanceMeters: _asDouble(json['distanceMeters'] ?? json['distance']),
      durationSeconds: _asInt(json['durationSeconds'] ?? json['duration']),
      tags: _asStringList(json['tags']),
      shopsEncountered: _asStringList(json['shopsEncountered']),
      pathPoints: (json['pathPoints'] as List<dynamic>? ?? const [])
          .map((item) => GeoPoint.fromJson(item as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'journeyId': journeyId,
    'type': type,
    'status': status,
    'startName': startName,
    'startLat': startPoint.latitude,
    'startLng': startPoint.longitude,
    'destinationName': destinationName,
    'destLat': destinationPoint?.latitude,
    'destLng': destinationPoint?.longitude,
    'startTime': startTime.toIso8601String(),
    'distanceMeters': distanceMeters,
    'durationSeconds': durationSeconds,
    'tags': tags,
    'shopsEncountered': shopsEncountered,
    'pathPoints': pathPoints.map((item) => item.toJson()).toList(),
  };
}

class JourneyDetail {
  const JourneyDetail({
    required this.journeyId,
    required this.type,
    required this.status,
    required this.startName,
    required this.startPoint,
    required this.startTime,
    required this.tags,
    required this.shopsEncountered,
    required this.pathPoints,
    this.endName,
    this.endPoint,
    this.endTime,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
  });

  final String journeyId;
  final String type;
  final String status;
  final String startName;
  final GeoPoint startPoint;
  final String? endName;
  final GeoPoint? endPoint;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final int durationSeconds;
  final List<String> tags;
  final List<String> shopsEncountered;
  final List<GeoPoint> pathPoints;

  factory JourneyDetail.fromJson(Map<dynamic, dynamic> json) {
    return JourneyDetail(
      journeyId: _asString(json['journeyId']),
      type: _asString(json['type']),
      status: _asString(json['status']),
      startName: _asString(json['startName']),
      startPoint: GeoPoint(
        latitude: _asDouble(json['startLat']),
        longitude: _asDouble(json['startLng']),
      ),
      endName: json['endName']?.toString(),
      endPoint: json['endLat'] == null && json['endLng'] == null
          ? null
          : GeoPoint(
              latitude: _asDouble(json['endLat']),
              longitude: _asDouble(json['endLng']),
            ),
      startTime:
          DateTime.tryParse(_asString(json['startTime'])) ?? DateTime.now(),
      endTime: DateTime.tryParse(_asString(json['endTime'])),
      distanceMeters: _asDouble(json['distance']),
      durationSeconds: _asInt(json['duration']),
      tags: _asStringList(json['tags']),
      shopsEncountered: _asStringList(json['shopsEncountered']),
      pathPoints: (json['pathPoints'] as List<dynamic>? ?? const [])
          .map((item) => GeoPoint.fromJson(item as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class SavedItem {
  const SavedItem({
    required this.favouriteId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.savedAt,
    this.offerId,
    this.shopId,
    this.address,
    this.point,
    this.imageUrl,
    this.discountPercentage,
    this.endDate,
    this.isVerified = false,
  });

  final String favouriteId;
  final String type;
  final String title;
  final String subtitle;
  final String? offerId;
  final String? shopId;
  final String? address;
  final GeoPoint? point;
  final String? imageUrl;
  final double? discountPercentage;
  final DateTime? endDate;
  final bool isVerified;
  final DateTime savedAt;

  factory SavedItem.fromJson(Map<dynamic, dynamic> json) {
    return SavedItem(
      favouriteId: _asString(json['favouriteId']),
      type: _asString(json['type']),
      title: _asString(json['title']),
      subtitle: _asString(json['subtitle']),
      offerId: json['offerId']?.toString(),
      shopId: json['shopId']?.toString(),
      address: json['address']?.toString(),
      point: json['latitude'] == null && json['longitude'] == null
          ? null
          : GeoPoint(
              latitude: _asDouble(json['latitude']),
              longitude: _asDouble(json['longitude']),
            ),
      imageUrl: json['imageUrl']?.toString(),
      discountPercentage: json['discountPercentage'] == null
          ? null
          : _asDouble(json['discountPercentage']),
      endDate: DateTime.tryParse(_asString(json['endDate'])),
      isVerified: json['isVerified'] == true,
      savedAt: DateTime.tryParse(_asString(json['savedAt'])) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'favouriteId': favouriteId,
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'offerId': offerId,
    'shopId': shopId,
    'address': address,
    'latitude': point?.latitude,
    'longitude': point?.longitude,
    'imageUrl': imageUrl,
    'discountPercentage': discountPercentage,
    'endDate': endDate?.toIso8601String(),
    'isVerified': isVerified,
    'savedAt': savedAt.toIso8601String(),
  };
}

class UserNotificationItem {
  const UserNotificationItem({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.actionOfferId,
    this.actionShopId,
    this.actionJourneyId,
    this.metadataJson,
  });

  final String notificationId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  final String? actionOfferId;
  final String? actionShopId;
  final String? actionJourneyId;
  final String? metadataJson;

  factory UserNotificationItem.fromJson(Map<dynamic, dynamic> json) {
    return UserNotificationItem(
      notificationId: _asString(json['notificationId']),
      title: _asString(json['title']),
      message: _asString(json['message']),
      type: _asString(json['type']),
      priority: _asString(json['priority']),
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse(_asString(json['createdAt'])) ?? DateTime.now(),
      actionOfferId: json['actionOfferId']?.toString(),
      actionShopId: json['actionShopId']?.toString(),
      actionJourneyId: json['actionJourneyId']?.toString(),
      metadataJson: json['metadataJson']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'title': title,
    'message': message,
    'type': type,
    'priority': priority,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'actionOfferId': actionOfferId,
    'actionShopId': actionShopId,
    'actionJourneyId': actionJourneyId,
    'metadataJson': metadataJson,
  };
}

class OfferDetail {
  const OfferDetail({
    required this.offerId,
    required this.shopId,
    required this.title,
    required this.description,
    required this.shopName,
    required this.endDate,
    required this.isSaved,
    required this.tags,
    this.shopAddress,
    this.category,
    this.point,
    this.imageUrl,
    this.discountPercentage,
    this.minOrderValue,
    this.termsAndConditions,
  });

  final String offerId;
  final String shopId;
  final String title;
  final String description;
  final String shopName;
  final String? shopAddress;
  final String? category;
  final GeoPoint? point;
  final String? imageUrl;
  final double? discountPercentage;
  final double? minOrderValue;
  final DateTime endDate;
  final bool isSaved;
  final List<String> tags;
  final String? termsAndConditions;

  factory OfferDetail.fromJson(Map<dynamic, dynamic> json) {
    return OfferDetail(
      offerId: _asString(json['offerId']),
      shopId: _asString(json['shopId']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      shopName: _asString(json['shopName']),
      shopAddress: json['shopAddress']?.toString(),
      category: json['category']?.toString(),
      point: json['latitude'] == null && json['longitude'] == null
          ? null
          : GeoPoint(
              latitude: _asDouble(json['latitude']),
              longitude: _asDouble(json['longitude']),
            ),
      imageUrl: json['imageUrl']?.toString(),
      discountPercentage: json['discountPercentage'] == null
          ? null
          : _asDouble(json['discountPercentage']),
      minOrderValue: json['minOrderValue'] == null
          ? null
          : _asDouble(json['minOrderValue']),
      endDate: DateTime.tryParse(_asString(json['endDate'])) ?? DateTime.now(),
      isSaved: json['isSaved'] == true,
      tags: _asStringList(json['tags']),
      termsAndConditions: json['termsAndConditions']?.toString(),
    );
  }
}

class ShopOfferSummary {
  const ShopOfferSummary({
    required this.offerId,
    required this.title,
    required this.status,
    required this.endDate,
  });

  final String offerId;
  final String title;
  final String status;
  final DateTime endDate;

  factory ShopOfferSummary.fromJson(Map<dynamic, dynamic> json) {
    return ShopOfferSummary(
      offerId: _asString(json['offerId']),
      title: _asString(json['title']),
      status: _asString(json['status']),
      endDate: DateTime.tryParse(_asString(json['endDate'])) ?? DateTime.now(),
    );
  }
}

class ShopDetail {
  const ShopDetail({
    required this.shopId,
    required this.name,
    required this.keeperId,
    required this.isActive,
    required this.isVerified,
    required this.isOpen,
    required this.tags,
    required this.amenities,
    required this.recentOffers,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
    this.point,
    this.categoryName,
    this.keeperBusinessName,
    this.notificationRadius,
    this.imageUrl,
  });

  final String shopId;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final GeoPoint? point;
  final String? categoryName;
  final String? keeperBusinessName;
  final String keeperId;
  final bool isActive;
  final bool isVerified;
  final bool isOpen;
  final double? notificationRadius;
  final String? imageUrl;
  final List<String> tags;
  final List<String> amenities;
  final List<ShopOfferSummary> recentOffers;

  factory ShopDetail.fromJson(Map<dynamic, dynamic> json) {
    return ShopDetail(
      shopId: _asString(json['shopId']),
      name: _asString(json['name']),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      point: json['latitude'] == null && json['longitude'] == null
          ? null
          : GeoPoint(
              latitude: _asDouble(json['latitude']),
              longitude: _asDouble(json['longitude']),
            ),
      categoryName: json['categoryName']?.toString(),
      keeperBusinessName: json['keeperBusinessName']?.toString(),
      keeperId: _asString(json['keeperId']),
      isActive: json['isActive'] == true,
      isVerified: json['isVerified'] == true,
      isOpen: json['isOpen'] == true,
      notificationRadius: json['notificationRadius'] == null
          ? null
          : _asDouble(json['notificationRadius']),
      imageUrl: json['imageUrl']?.toString(),
      tags: _asStringList(json['tags']),
      amenities: _asStringList(json['amenities']),
      recentOffers: (json['recentOffers'] as List<dynamic>? ?? const [])
          .map(
            (item) => ShopOfferSummary.fromJson(item as Map<dynamic, dynamic>),
          )
          .toList(),
    );
  }
}
