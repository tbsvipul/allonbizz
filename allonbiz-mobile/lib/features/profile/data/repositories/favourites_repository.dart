import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';

final favouritesRepositoryProvider = Provider<FavouritesRepository>((ref) {
  return FavouritesRepository(apiClient: ref.watch(apiClientProvider));
});

class SavedItem {
  const SavedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.offerId,
    this.shopId,
    this.address,
    this.imageUrl,
    this.shopProfileImage,
    this.shopIsOpen,
    this.discountPercentage,
    this.endDate,
    this.isVerified = false,
  });

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String? offerId;
  final String? shopId;
  final String? address;
  final String? imageUrl;
  final String? shopProfileImage;
  final bool? shopIsOpen;
  final double? discountPercentage;
  final DateTime? endDate;
  final bool isVerified;

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id:
          json['favouriteId']?.toString() ??
          json['FavouriteId']?.toString() ??
          '',
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? json['Subtitle'] ?? '').toString(),
      offerId: json['offerId']?.toString() ?? json['OfferId']?.toString(),
      shopId: json['shopId']?.toString() ?? json['ShopId']?.toString(),
      address: (json['address'] ?? json['Address'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      shopProfileImage: (json['shopProfileImage'] ?? json['ShopProfileImage'])
          ?.toString(),
      shopIsOpen: json['shopIsOpen'] as bool? ?? json['ShopIsOpen'] as bool?,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ??
          (json['DiscountPercentage'] as num?)?.toDouble(),
      endDate: DateTime.tryParse(
        (json['endDate'] ?? json['EndDate'] ?? '').toString(),
      ),
      isVerified:
          json['isVerified'] as bool? ?? json['IsVerified'] as bool? ?? false,
    );
  }
}

class FavouritesRepository {
  final ApiClient _apiClient;

  FavouritesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<SavedItem>> getFavourites() async {
    try {
      final response = await _apiClient.get('/user/favourites');
      final data = response['data'];
      if (data is List) {
        return data
            .map((item) => SavedItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> toggleFavourite({String? shopId, String? offerId}) async {
    try {
      await _apiClient.post(
        '/user/favourites',
        body: {
          ...?shopId == null ? null : {'shopId': shopId},
          ...?offerId == null ? null : {'offerId': offerId},
          'type': shopId != null ? 'shop' : 'offer',
        },
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
