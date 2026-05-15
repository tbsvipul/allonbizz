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
    return Shop(
      id: json['shopId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Shop',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      offers: (json['offers'] as List?)
              ?.map((o) => Offer.fromJson(Map<String, dynamic>.from(o)))
              .toList() ??
          [],
    );
  }
}
