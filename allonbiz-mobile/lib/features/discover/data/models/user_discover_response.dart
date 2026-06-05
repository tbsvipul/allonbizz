import 'package:equatable/equatable.dart';

import '../../../../core/models/discovery_model.dart';
import '../../../../core/network/api_parsers.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/models/shop.dart';

final class UserDiscoverResponse extends Equatable {
  const UserDiscoverResponse({
    required this.categories,
    required this.tags,
    required this.offers,
    required this.shops,
    required this.personalization,
  });

  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final List<DiscoverOfferResult> offers;
  final List<DiscoverShopResult> shops;
  final UserDiscoverPersonalization personalization;

  factory UserDiscoverResponse.fromEnvelope(Object? response) {
    return UserDiscoverResponse.fromJson(extractEnvelopeDataMap(response));
  }

  factory UserDiscoverResponse.fromJson(Map<String, dynamic> json) {
    return UserDiscoverResponse(
      categories:
          asJsonMapList(firstPresent(json, ['categories', 'Categories']))
              .map(parseCategoryJson)
              .where((category) => category.label.trim().isNotEmpty)
              .toList(growable: false),
      tags: asJsonMapList(firstPresent(json, ['tags', 'Tags']))
          .map(parseTagJson)
          .where((tag) => tag.name.trim().isNotEmpty)
          .toList(growable: false),
      offers: asJsonMapList(firstPresent(json, ['offers', 'Offers']))
          .map(DiscoverOfferResult.fromJson)
          .where((result) => result.offer.id.trim().isNotEmpty)
          .toList(growable: false),
      shops: asJsonMapList(firstPresent(json, ['shops', 'Shops']))
          .map(DiscoverShopResult.fromJson)
          .where((result) => result.shop.id.trim().isNotEmpty)
          .toList(growable: false),
      personalization: UserDiscoverPersonalization.fromJson(
        asJsonMap(firstPresent(json, ['personalization', 'Personalization'])),
      ),
    );
  }

  static const empty = UserDiscoverResponse(
    categories: [],
    tags: [],
    offers: [],
    shops: [],
    personalization: UserDiscoverPersonalization.empty,
  );

  @override
  List<Object?> get props => [categories, tags, offers, shops, personalization];
}

final class DiscoverOfferResult extends Equatable {
  const DiscoverOfferResult({
    required this.offer,
    this.distanceKm,
    required this.matchScore,
    required this.matchReason,
  });

  final Offer offer;
  final double? distanceKm;
  final double matchScore;
  final String matchReason;

  factory DiscoverOfferResult.fromJson(Map<String, dynamic> json) {
    return DiscoverOfferResult(
      offer: parseOfferJson(json),
      distanceKm: nullableDoubleValue(json, ['distanceKm', 'DistanceKm']),
      matchScore: doubleValue(json, ['matchScore', 'MatchScore']),
      matchReason: stringValue(json, [
        'matchReason',
        'MatchReason',
      ], fallback: 'Recommended for you'),
    );
  }

  @override
  List<Object?> get props => [offer, distanceKm, matchScore, matchReason];
}

final class DiscoverShopResult extends Equatable {
  const DiscoverShopResult({
    required this.shop,
    required this.category,
    required this.activeOfferCount,
    this.distanceKm,
    required this.matchScore,
    required this.matchReason,
  });

  final Shop shop;
  final String category;
  final int activeOfferCount;
  final double? distanceKm;
  final double matchScore;
  final String matchReason;

  factory DiscoverShopResult.fromJson(Map<String, dynamic> json) {
    return DiscoverShopResult(
      shop: parseShopJson(json),
      category: stringValue(json, [
        'category',
        'categoryName',
        'Category',
        'CategoryName',
      ], fallback: 'General'),
      activeOfferCount: intValue(json, [
        'activeOfferCount',
        'ActiveOfferCount',
      ]),
      distanceKm: nullableDoubleValue(json, ['distanceKm', 'DistanceKm']),
      matchScore: doubleValue(json, ['matchScore', 'MatchScore']),
      matchReason: stringValue(json, [
        'matchReason',
        'MatchReason',
      ], fallback: 'Recommended shop'),
    );
  }

  @override
  List<Object?> get props => [
    shop,
    category,
    activeOfferCount,
    distanceKm,
    matchScore,
    matchReason,
  ];
}

final class UserDiscoverPersonalization extends Equatable {
  const UserDiscoverPersonalization({
    required this.hasHistory,
    required this.strategy,
    required this.interestTags,
    required this.encounteredShops,
  });

  final bool hasHistory;
  final String strategy;
  final List<String> interestTags;
  final List<String> encounteredShops;

  factory UserDiscoverPersonalization.fromJson(Map<String, dynamic> json) {
    return UserDiscoverPersonalization(
      hasHistory: boolValue(json, ['hasHistory', 'HasHistory']),
      strategy: stringValue(json, [
        'strategy',
        'Strategy',
      ], fallback: 'fallback'),
      interestTags: parseStringList(
        firstPresent(json, ['interestTags', 'InterestTags']),
      ),
      encounteredShops: parseStringList(
        firstPresent(json, ['encounteredShops', 'EncounteredShops']),
      ),
    );
  }

  static const empty = UserDiscoverPersonalization(
    hasHistory: false,
    strategy: 'fallback',
    interestTags: [],
    encounteredShops: [],
  );

  @override
  List<Object?> get props => [
    hasHistory,
    strategy,
    interestTags,
    encounteredShops,
  ];
}

final class UserDiscoverQuery extends Equatable {
  UserDiscoverQuery({
    this.search,
    this.categoryId,
    this.category,
    List<String> tags = const [],
    this.lat,
    this.lng,
    this.radiusKm,
    this.limit = 30,
    this.includeTaxonomy = true,
  }) : tags = List.unmodifiable(
         tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toSet(),
       );

  final String? search;
  final String? categoryId;
  final String? category;
  final List<String> tags;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final int limit;
  final bool includeTaxonomy;

  UserDiscoverQuery copyWith({
    String? search,
    String? categoryId,
    String? category,
    List<String>? tags,
    double? lat,
    double? lng,
    double? radiusKm,
    int? limit,
    bool? includeTaxonomy,
    bool clearCategory = false,
  }) {
    return UserDiscoverQuery(
      search: search ?? this.search,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      category: clearCategory ? null : category ?? this.category,
      tags: tags ?? this.tags,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      limit: limit ?? this.limit,
      includeTaxonomy: includeTaxonomy ?? this.includeTaxonomy,
    );
  }

  String get cacheKey {
    final buffer = StringBuffer('user-discover');
    final normalizedSearch = search?.trim().toLowerCase();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      buffer.write(':q=$normalizedSearch');
    }
    if (categoryId != null && categoryId!.isNotEmpty) {
      buffer.write(':catId=$categoryId');
    }
    if (category != null && category!.isNotEmpty) {
      buffer.write(':cat=${category!.toLowerCase()}');
    }
    if (tags.isNotEmpty) {
      buffer.write(':tags=${tags.map((tag) => tag.toLowerCase()).join(",")}');
    }
    if (lat != null) {
      buffer.write(':lat=${lat!.toStringAsFixed(3)}');
    }
    if (lng != null) {
      buffer.write(':lng=${lng!.toStringAsFixed(3)}');
    }
    if (radiusKm != null) {
      buffer.write(':r=${radiusKm!.toStringAsFixed(2)}');
    }
    buffer.write(':limit=$limit:taxonomy=$includeTaxonomy');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    search,
    categoryId,
    category,
    tags,
    lat,
    lng,
    radiusKm,
    limit,
    includeTaxonomy,
  ];
}
