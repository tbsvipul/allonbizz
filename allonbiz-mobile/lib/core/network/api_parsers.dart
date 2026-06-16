import 'package:flutter/material.dart';

import '../../shared/models/offer.dart';
import '../../shared/models/shop.dart';
import '../models/api_response.dart';
import '../models/discovery_model.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonParser<T> = T Function(JsonMap json);

JsonMap asJsonMap(Object? raw) {
  if (raw is JsonMap) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

List<JsonMap> asJsonMapList(Object? raw) {
  if (raw is! List) {
    return const <JsonMap>[];
  }

  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Object? firstPresent(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

String stringValue(JsonMap json, List<String> keys, {String fallback = ''}) {
  final value = firstPresent(json, keys);
  final stringified = value?.toString();
  if (stringified == null || stringified.isEmpty) {
    return fallback;
  }
  return stringified;
}

String? nullableStringValue(JsonMap json, List<String> keys) {
  final value = firstPresent(json, keys);
  final stringified = value?.toString();
  if (stringified == null || stringified.isEmpty) {
    return null;
  }
  return stringified;
}

double doubleValue(JsonMap json, List<String> keys, {double fallback = 0.0}) {
  final value = firstPresent(json, keys);
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int intValue(JsonMap json, List<String> keys, {int fallback = 0}) {
  final value = firstPresent(json, keys);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

int? nullableIntValue(JsonMap json, List<String> keys) {
  final value = firstPresent(json, keys);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? nullableDoubleValue(JsonMap json, List<String> keys) {
  final value = firstPresent(json, keys);
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

bool boolValue(JsonMap json, List<String> keys, {bool fallback = false}) {
  final value = firstPresent(json, keys);
  if (value is bool) {
    return value;
  }
  if (value is String) {
    if (value.toLowerCase() == 'true') {
      return true;
    }
    if (value.toLowerCase() == 'false') {
      return false;
    }
  }
  return fallback;
}

bool? nullableBoolValue(JsonMap json, List<String> keys) {
  final value = firstPresent(json, keys);
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return null;
}

DateTime? nullableDateValue(JsonMap json, List<String> keys) {
  final value = firstPresent(json, keys);
  if (value == null) {
    return null;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

List<String> parseStringList(Object? field) {
  if (field is List) {
    return field
        .map((tag) {
          if (tag is Map) {
            final tagJson = Map<String, dynamic>.from(tag);
            return stringValue(tagJson, [
              'name',
              'Name',
              'label',
              'Label',
              'title',
              'Title',
            ]);
          }
          return tag.toString().trim();
        })
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  if (field is String && field.trim().isNotEmpty) {
    return field
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}

JsonMap extractEnvelopeDataMap(Object? response) {
  return asJsonMap(firstPresent(asJsonMap(response), ['data', 'Data']));
}

List<JsonMap> extractEnvelopeDataList(Object? response) {
  return asJsonMapList(firstPresent(asJsonMap(response), ['data', 'Data']));
}

Offer parseOfferJson(JsonMap json) {
  return Offer(
    id: stringValue(json, ['id', 'offerId', 'OfferId', 'shopId', 'ShopId']),
    shopId: nullableStringValue(json, ['shopId', 'ShopId']),
    title: stringValue(json, [
      'title',
      'name',
      'Title',
      'Name',
    ], fallback: 'Deal'),
    description: stringValue(json, ['description', 'Description']),
    category: stringValue(json, ['category', 'Category'], fallback: 'misc'),
    discountPercent: doubleValue(json, [
      'discountPercent',
      'discountPercentage',
      'DiscountPercent',
      'DiscountPercentage',
    ]),
    shopName: stringValue(json, [
      'shopName',
      'name',
      'ShopName',
      'Name',
    ], fallback: 'Local Shop'),
    shopAddress: nullableStringValue(json, [
      'shopAddress',
      'address',
      'ShopAddress',
      'Address',
    ]),
    latitude: doubleValue(json, ['latitude', 'lat', 'Latitude']),
    longitude: doubleValue(json, ['longitude', 'lng', 'lon', 'Longitude']),
    imageUrl: nullableStringValue(json, [
      'imageUrl',
      'ImageUrl',
      'offerImageUrl',
      'OfferImageUrl',
      'imageData',
      'ImageData',
      'thumbnailUrl',
      'ThumbnailUrl',
    ]),
    shopProfileImage: nullableStringValue(json, [
      'shopProfileImage',
      'ShopProfileImage',
    ]),
    shopIsOpen: nullableBoolValue(json, ['shopIsOpen', 'ShopIsOpen']),
    expiresAt: nullableDateValue(json, ['expiresAt', 'EndDate', 'ExpiresAt']),
    terms: nullableStringValue(json, ['terms', 'TermsAndConditions', 'Terms']),
    keeperId: nullableStringValue(json, ['keeperId', 'KeeperId']),
    keeperName: nullableStringValue(json, ['keeperName', 'KeeperName']),
    keeperPhone: nullableStringValue(json, ['keeperPhone', 'KeeperPhone']),
    isActive: boolValue(json, ['isActive', 'IsActive'], fallback: true),

    rating: nullableDoubleValue(json, ['rating', 'Rating']),
    reviewCount: nullableIntValue(json, ['reviewCount', 'ReviewCount']),
    createdAt:
        nullableDateValue(json, ['createdAt', 'CreatedAt']) ?? DateTime.now(),
    distance: nullableStringValue(json, [
      'distance',
      'distanceKm',
      'DistanceKm',
    ]),
    isSaved: boolValue(json, ['isSaved', 'IsSaved']),
    tags: parseStringList(
      firstPresent(json, [
        'tags',
        'Tags',
        'tagNames',
        'TagNames',
        'offerTags',
        'OfferTags',
        'keywords',
        'Keywords',
      ]),
    ),
  );
}

List<Offer> parseOfferList(Object? rawList) {
  return asJsonMapList(rawList).map(parseOfferJson).toList(growable: false);
}

List<Offer> parseOffersEnvelope(Object? response) {
  return parseOfferList(firstPresent(asJsonMap(response), ['data', 'Data']));
}

List<Offer> parseRecommendedOffersFromHomeResponse(Object? response) {
  final data = extractEnvelopeDataMap(response);
  return parseOfferList(
    firstPresent(data, ['recommendedOffers', 'RecommendedOffers']),
  );
}

Shop parseShopJson(JsonMap json) {
  return Shop(
    id: stringValue(json, ['shopId', 'ShopId', 'id']),
    name: stringValue(json, ['name', 'Name'], fallback: 'Unknown Shop'),
    description: nullableStringValue(json, ['description', 'Description']),
    address: nullableStringValue(json, ['address', 'Address']),
    phoneNumber: nullableStringValue(json, ['phoneNumber', 'PhoneNumber']),
    email: nullableStringValue(json, ['email', 'Email']),
    shopProfileImage: nullableStringValue(json, [
      'shopProfileImage',
      'ShopProfileImage',
    ]),
    latitude: doubleValue(json, ['latitude', 'Latitude']),
    longitude: doubleValue(json, ['longitude', 'Longitude']),
    isOpen: boolValue(json, ['isOpen', 'IsOpen'], fallback: true),
    shopImages: parseStringList(
      firstPresent(json, ['shopImages', 'ShopImages']),
    ),
    tags: parseStringList(firstPresent(json, ['tags', 'Tags'])),
    offers: parseOfferList(
      firstPresent(json, ['offers', 'Offers', 'recentOffers', 'RecentOffers']),
    ),
  );
}

Shop parseShopEnvelope(Object? response) {
  return parseShopJson(extractEnvelopeDataMap(response));
}

Shop parseJourneyNearbyShopJson(JsonMap json) {
  return Shop(
    id: stringValue(json, ['shopId', 'ShopId', 'id']),
    name: stringValue(json, ['name', 'Name'], fallback: 'Unknown Shop'),
    address: nullableStringValue(json, ['address', 'Address']),
    shopProfileImage: nullableStringValue(json, [
      'shopProfileImage',
      'ShopProfileImage',
    ]),
    latitude: doubleValue(json, ['latitude', 'Latitude']),
    longitude: doubleValue(json, ['longitude', 'Longitude']),
    tags: parseStringList(firstPresent(json, ['tags', 'Tags'])),
    isOpen: boolValue(json, ['isOpen', 'IsOpen'], fallback: false),
  );
}

CategoryModel parseCategoryJson(JsonMap json) {
  return CategoryModel(
    id: stringValue(json, ['id', 'categoryId', 'CategoryId']),
    label: stringValue(json, ['label', 'name', 'Label', 'Name']),
    iconCode:
        nullableIntValue(json, ['iconCode', 'IconCode']) ??
        int.tryParse(
          stringValue(json, ['icon', 'Icon', 'iconData', 'IconData']),
        ) ??
        Icons.help_outline.codePoint,
    colorHex: stringValue(json, [
      'colorHex',
      'color',
      'ColorHex',
      'Color',
    ], fallback: '0xFF9E9E9E'),
  );
}

List<JsonMap> flattenCategoryTree(List<JsonMap> items) {
  final flattened = <JsonMap>[];

  for (final item in items) {
    flattened.add(item);
    final children = firstPresent(item, ['children', 'Children']);
    final nestedChildren = asJsonMapList(children);
    if (nestedChildren.isNotEmpty) {
      flattened.addAll(flattenCategoryTree(nestedChildren));
    }
  }

  return flattened;
}

List<CategoryModel> parseCategoriesEnvelope(Object? response) {
  final items = extractEnvelopeDataList(response);
  return flattenCategoryTree(items)
      .map(parseCategoryJson)
      .where((category) => category.label.trim().isNotEmpty)
      .toList(growable: false);
}

TagModel parseTagJson(JsonMap json) {
  final name = stringValue(json, ['name', 'Name']);
  return TagModel(
    id: stringValue(json, ['id', 'tagId', 'TagId']),
    name: name,
    color: nullableStringValue(json, ['color', 'Color']),
    iconCode:
        nullableIntValue(json, ['iconCode', 'IconCode']) ??
        int.tryParse(
          stringValue(json, ['icon', 'Icon', 'iconData', 'IconData']),
        ) ??
        TagModel.guessIcon(name).codePoint,
  );
}

List<TagModel> parseTagsEnvelope(Object? response) {
  return extractEnvelopeDataList(response)
      .map(parseTagJson)
      .where((tag) => tag.name.trim().isNotEmpty)
      .toList(growable: false);
}

ApiPage<T> parseApiPageEnvelope<T>(
  Object? response,
  T Function(JsonMap json) fromJson,
) {
  return ApiPage.fromJson(
    asJsonMap(response),
    (json) => fromJson(asJsonMap(json)),
  );
}
