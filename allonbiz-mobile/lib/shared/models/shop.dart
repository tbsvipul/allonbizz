import 'offer.dart';

class Shop {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? shopProfileImage;
  final List<String> shopImages;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final List<Offer> offers;
  final bool isOpen;

  Shop({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
    this.shopProfileImage,
    this.shopImages = const [],
    this.tags = const [],
    required this.latitude,
    required this.longitude,
    this.offers = const [],
    this.isOpen = true,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawOffers =
        json['offers'] ??
        json['Offers'] ??
        json['recentOffers'] ??
        json['RecentOffers'];

    final rawImages = json['shopImages'] ?? json['ShopImages'] ?? [];

    return Shop(
      id:
          json['shopId']?.toString() ??
          json['ShopId']?.toString() ??
          json['id']?.toString() ??
          '',
      name:
          json['name']?.toString() ??
          json['Name']?.toString() ??
          'Unknown Shop',
      description:
          json['description']?.toString() ?? json['Description']?.toString(),
      address: json['address']?.toString() ?? json['Address']?.toString(),
      phoneNumber:
          json['phoneNumber']?.toString() ?? json['PhoneNumber']?.toString(),
      email: json['email']?.toString() ?? json['Email']?.toString(),
      shopProfileImage:
          json['shopProfileImage']?.toString() ??
          json['ShopProfileImage']?.toString(),
      latitude:
          (json['latitude'] as num?)?.toDouble() ??
          (json['Latitude'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ??
          (json['Longitude'] as num?)?.toDouble() ??
          0.0,
      shopImages: (rawImages as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: Offer.parseTags(json['tags'] ?? json['Tags']),
      isOpen: json['isOpen'] as bool? ?? json['IsOpen'] as bool? ?? true,
      offers:
          (rawOffers as List?)
              ?.map((offer) => Offer.fromJson(Map<String, dynamic>.from(offer)))
              .toList() ??
          [],
    );
  }

  String? get primaryImageUrl {
    final normalizedProfileImage = shopProfileImage?.trim();
    if (normalizedProfileImage != null && normalizedProfileImage.isNotEmpty) {
      return normalizedProfileImage;
    }

    for (final candidate in shopImages) {
      final normalized = candidate.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }
}
