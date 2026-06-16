import 'package:equatable/equatable.dart';

/// Data model for local deals and offers along routes.
final class Offer extends Equatable {
  const Offer({
    required this.id,
    this.shopId,
    required this.title,
    required this.description,
    required this.category,
    required this.discountPercent,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.shopName = 'Local Shop',
    this.shopAddress,
    this.imageUrl,
    this.shopProfileImage,
    this.shopIsOpen,
    this.expiresAt,
    this.terms,
    this.keeperId,
    this.keeperName,
    this.keeperPhone,
    this.isActive = true,

    this.rating,
    this.reviewCount,
    this.distance,
    this.isSaved = false,
    this.tags = const [],
  });

  final String id;
  final String? shopId;
  final String title;
  final String description;
  final String category;
  final double discountPercent;
  final String shopName;
  final String? shopAddress;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? shopProfileImage;
  final bool? shopIsOpen;
  final DateTime? expiresAt;
  final String? terms;
  final String? keeperId;
  final String? keeperName;
  final String? keeperPhone;
  final bool isActive;

  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final String? distance; // Temporary UI field for display
  final bool isSaved;
  final List<String> tags;

  factory Offer.fromMap(Map<String, dynamic> data) {
    return Offer(
      id: data['id'] as String,
      shopId: data['shopId'] as String?,
      title: data['title'] as String? ?? 'Deal',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'misc',
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      shopName: data['shopName'] as String? ?? 'Local Shop',
      shopAddress: data['shopAddress'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String?,
      shopProfileImage: data['shopProfileImage'] as String?,
      shopIsOpen: _parseNullableBool(data['shopIsOpen']),
      expiresAt: _parseNullableTimestamp(data['expiresAt']),
      terms: data['terms'] as String?,
      keeperId: data['keeperId'] as String?,
      keeperName: data['keeperName'] as String?,
      keeperPhone: data['keeperPhone'] as String?,
      isActive: data['isActive'] as bool? ?? true,

      createdAt: _parseTimestamp(data['createdAt']),
      distance: null,
      isSaved: data['isSaved'] as bool? ?? false,
      tags: parseTags(data['tags']),
    );
  }

  factory Offer.fromJson(Map<String, dynamic> json, {String? id}) {
    // Handle both camelCase and PascalCase/specialized DTO keys
    final String effectiveId =
        id ??
        json['id']?.toString() ??
        json['offerId']?.toString() ??
        json['shopId']?.toString() ??
        json['OfferId']?.toString() ??
        '';

    final String effectiveTitle =
        (json['title'] ??
                json['name'] ??
                json['Title'] ??
                json['Name'] ??
                'Deal')
            .toString();
    final String effectiveShopName =
        (json['shopName'] ??
                json['name'] ??
                json['ShopName'] ??
                json['Name'] ??
                'Local Shop')
            .toString();
    final String? effectiveAddress =
        (json['shopAddress'] ??
                json['address'] ??
                json['ShopAddress'] ??
                json['Address'])
            ?.toString();

    return Offer(
      id: effectiveId,
      shopId: json['shopId']?.toString() ?? json['ShopId']?.toString(),
      title: effectiveTitle,
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      category: (json['category'] ?? json['Category'] ?? 'misc').toString(),
      discountPercent:
          (json['discountPercent'] as num?)?.toDouble() ??
          (json['discountPercentage'] as num?)?.toDouble() ??
          0.0,
      shopName: effectiveShopName,
      shopAddress: effectiveAddress,
      latitude:
          (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          (json['Latitude'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          (json['Longitude'] as num?)?.toDouble() ??
          0.0,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      shopProfileImage: (json['shopProfileImage'] ?? json['ShopProfileImage'])
          ?.toString(),
      shopIsOpen: _parseNullableBool(json['shopIsOpen'] ?? json['ShopIsOpen']),
      expiresAt: _parseDate(json['expiresAt'] ?? json['EndDate']),
      terms: (json['terms'] ?? json['TermsAndConditions'])?.toString(),
      keeperId: (json['keeperId'] ?? json['KeeperId'])?.toString(),
      keeperName: (json['keeperName'] ?? json['KeeperName'])?.toString(),
      keeperPhone: (json['keeperPhone'] ?? json['KeeperPhone'])?.toString(),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,

      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      distance: json['distance']?.toString() ?? json['distanceKm']?.toString(),
      isSaved: json['isSaved'] as bool? ?? json['IsSaved'] as bool? ?? false,
      tags: parseTags(
        json['tags'] ??
            json['Tags'] ??
            json['tagNames'] ??
            json['TagNames'] ??
            json['offerTags'] ??
            json['OfferTags'] ??
            json['keywords'] ??
            json['Keywords'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (shopId != null) 'shopId': shopId,
    'title': title,
    'description': description,
    'category': category,
    'discountPercent': discountPercent,
    'shopName': shopName,
    if (shopAddress != null) 'shopAddress': shopAddress,
    'latitude': latitude,
    'longitude': longitude,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (shopProfileImage != null) 'shopProfileImage': shopProfileImage,
    if (shopIsOpen != null) 'shopIsOpen': shopIsOpen,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (terms != null) 'terms': terms,
    if (keeperId != null) 'keeperId': keeperId,
    if (keeperName != null) 'keeperName': keeperName,
    if (keeperPhone != null) 'keeperPhone': keeperPhone,
    'isActive': isActive,

    if (rating != null) 'rating': rating,
    if (reviewCount != null) 'reviewCount': reviewCount,
    'createdAt': createdAt.toIso8601String(),
    'isSaved': isSaved,
    if (tags.isNotEmpty) 'tags': tags,
  };

  Offer copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? discountPercent,
    String? shopName,
    String? shopAddress,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? shopProfileImage,
    bool? shopIsOpen,
    DateTime? expiresAt,
    String? terms,
    String? keeperId,
    String? keeperName,
    String? keeperPhone,
    bool? isActive,

    DateTime? createdAt,
    String? distance,
    bool? isSaved,
    List<String>? tags,
  }) {
    return Offer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      discountPercent: discountPercent ?? this.discountPercent,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      shopProfileImage: shopProfileImage ?? this.shopProfileImage,
      shopIsOpen: shopIsOpen ?? this.shopIsOpen,
      expiresAt: expiresAt ?? this.expiresAt,
      terms: terms ?? this.terms,
      keeperId: keeperId ?? this.keeperId,
      keeperName: keeperName ?? this.keeperName,
      keeperPhone: keeperPhone ?? this.keeperPhone,
      isActive: isActive ?? this.isActive,

      createdAt: createdAt ?? this.createdAt,
      distance: distance ?? this.distance,
      isSaved: isSaved ?? this.isSaved,
      tags: tags ?? this.tags,
    );
  }

  static DateTime? _parseDate(dynamic field) {
    if (field == null) return null;
    if (field is String) return DateTime.tryParse(field);
    if (field is int) return DateTime.fromMillisecondsSinceEpoch(field);
    return null;
  }

  static DateTime _parseTimestamp(dynamic field) =>
      _parseDate(field) ?? DateTime.now();
  static DateTime? _parseNullableTimestamp(dynamic field) => _parseDate(field);

  static bool? _parseNullableBool(dynamic field) {
    if (field is bool) {
      return field;
    }
    if (field is String) {
      final normalized = field.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  static List<String> parseTags(dynamic field) {
    if (field is List) {
      return field
          .map((tag) {
            if (tag is Map) {
              return (tag['name'] ??
                      tag['Name'] ??
                      tag['label'] ??
                      tag['Label'] ??
                      tag['title'] ??
                      tag['Title'] ??
                      '')
                  .toString()
                  .trim();
            }
            return tag.toString().trim();
          })
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    if (field is String && field.trim().isNotEmpty) {
      return field
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    discountPercent,
    shopName,
    shopAddress,
    latitude,
    longitude,
    imageUrl,
    shopProfileImage,
    shopIsOpen,
    expiresAt,
    terms,
    keeperId,
    keeperName,
    keeperPhone,
    isActive,

    createdAt,
    distance,
    isSaved,
    tags,
  ];

  @override
  String toString() => 'Offer(id: $id, title: $title)';
}
