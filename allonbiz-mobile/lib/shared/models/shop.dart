import 'offer.dart';

class Shop {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final List<Offer> offers;

  Shop({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.offers = const [],
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawOffers =
        json['offers'] ??
        json['Offers'] ??
        json['recentOffers'] ??
        json['RecentOffers'];

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
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      latitude:
          (json['latitude'] as num?)?.toDouble() ??
          (json['Latitude'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ??
          (json['Longitude'] as num?)?.toDouble() ??
          0.0,
      offers:
          (rawOffers as List?)
              ?.map((offer) => Offer.fromJson(Map<String, dynamic>.from(offer)))
              .toList() ??
          [],
    );
  }
}
