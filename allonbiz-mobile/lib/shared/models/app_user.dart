import 'package:equatable/equatable.dart';

/// Data model for the app user profile fetched from the backend API.
final class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.createdAt,
    required this.lastLoginAt,
    this.displayName,
    this.email,
    this.photoUrl,
    this.phone,
    this.totalSaved = 0.0,
    this.totalKm = 0.0,
    this.totalTrips = 0,

    this.savedOfferIds = const [],
    this.fcmToken,
    this.safetyMode = false,
    this.languageCode = 'en',
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? phone;
  final double totalSaved;
  final double totalKm;
  final int totalTrips;

  final List<String> savedOfferIds;
  final String? fcmToken;
  final bool safetyMode;
  final String languageCode;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  factory AppUser.fromJson(Map<String, dynamic> json, {String? uid}) {
    final firstName = json['firstName'] ?? json['FirstName'] as String? ?? '';
    final lastName = json['lastName'] ?? json['LastName'] as String? ?? '';
    final displayName =
        json['displayName'] ??
        json['DisplayName'] ??
        (firstName.isNotEmpty ? '$firstName $lastName' : null);

    return AppUser(
      uid:
          uid ??
          json['userId'] ??
          json['UserId'] ??
          json['uid'] ??
          json['id'] ??
          '',
      displayName: displayName as String?,
      email: (json['email'] ?? json['Email']) as String?,
      photoUrl:
          json['photoUrl'] ??
          json['PhotoUrl'] ??
          json['profilePhotoUrl'] ??
          json['ProfilePhotoUrl'] as String?,
      phone:
          json['phone'] ??
          json['Phone'] ??
          json['phoneNumber'] ??
          json['PhoneNumber'] as String?,
      totalSaved:
          (json['totalSaved'] ?? json['TotalSaved'] as num?)?.toDouble() ?? 0.0,
      totalKm: (json['totalKm'] ?? json['TotalKm'] as num?)?.toDouble() ?? 0.0,
      totalTrips: json['totalTrips'] ?? json['TotalTrips'] as int? ?? 0,

      savedOfferIds: List<String>.from(
        json['savedOfferIds'] ?? json['SavedOfferIds'] as Iterable? ?? [],
      ),
      fcmToken: json['fcmToken'] ?? json['FcmToken'] as String?,
      safetyMode: json['safetyMode'] ?? json['SafetyMode'] as bool? ?? false,
      languageCode:
          json['languageCode'] ?? json['LanguageCode'] as String? ?? 'en',
      createdAt: _parseDate(json['createdAt'] ?? json['CreatedAt']),
      lastLoginAt: _parseDate(json['lastLoginAt'] ?? json['LastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'phone': phone,
    'totalSaved': totalSaved,
    'totalKm': totalKm,
    'totalTrips': totalTrips,

    'savedOfferIds': savedOfferIds,
    if (fcmToken != null) 'fcmToken': fcmToken,
    'safetyMode': safetyMode,
    'languageCode': languageCode,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
  };

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? phone,
    double? totalSaved,
    double? totalKm,
    int? totalTrips,

    List<String>? savedOfferIds,
    String? fcmToken,
    bool? safetyMode,
    String? languageCode,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      totalSaved: totalSaved ?? this.totalSaved,
      totalKm: totalKm ?? this.totalKm,
      totalTrips: totalTrips ?? this.totalTrips,

      savedOfferIds: savedOfferIds ?? this.savedOfferIds,
      fcmToken: fcmToken ?? this.fcmToken,
      safetyMode: safetyMode ?? this.safetyMode,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  static DateTime _parseDate(dynamic field) {
    if (field == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (field is String) {
      return DateTime.tryParse(field) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (field is int) return DateTime.fromMillisecondsSinceEpoch(field);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    email,
    photoUrl,
    phone,
    totalSaved,
    totalKm,
    totalTrips,

    savedOfferIds,
    fcmToken,
    safetyMode,
    languageCode,
    createdAt,
    lastLoginAt,
  ];

  @override
  String toString() => 'AppUser(uid: $uid, email: $email)';
}
