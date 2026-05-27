enum JourneyType { destination, freeRoam }

class JourneyPathPoint {
  final double latitude;
  final double longitude;

  const JourneyPathPoint({required this.latitude, required this.longitude});

  factory JourneyPathPoint.fromJson(Map<String, dynamic> json) {
    return JourneyPathPoint(
      latitude:
          (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class JourneyModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String status;
  final JourneyType type;
  final double startLat;
  final double startLng;
  final double? endLat;
  final double? endLng;
  final String? startName;
  final String? endName;
  final DateTime startTimeDate;
  final DateTime? endTimeDate;
  final double distance; // meters
  final int duration; // seconds
  final List<String> shopsEncountered;
  final List<String> tags;
  final List<JourneyPathPoint> pathPoints;

  JourneyModel({
    this.id,
    required this.userId,
    required this.userEmail,
    this.status = '',
    required this.type,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
    this.startName,
    this.endName,
    required this.startTimeDate,
    this.endTimeDate,
    this.distance = 0.0,
    this.duration = 0,
    this.shopsEncountered = const [],
    this.tags = const [],
    this.pathPoints = const [],
  });

  bool get isCompleted => endTimeDate != null;

  factory JourneyModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return JourneyModel(
      id: id ?? json['id']?.toString() ?? json['journeyId']?.toString(),
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail'] ?? '',
      status: json['status']?.toString() ?? '',
      type: _parseType(json['type']),
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0.0,
      startLng: (json['startLng'] as num?)?.toDouble() ?? 0.0,
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: (json['endLng'] as num?)?.toDouble(),
      startName: json['startName'],
      endName: json['endName'],
      startTimeDate:
          _parseDate(json['startTimeDate'] ?? json['startTime']) ??
          DateTime.now(),
      endTimeDate: _parseDate(json['endTimeDate'] ?? json['endTime']),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      shopsEncountered: _parseEncounteredShops(json['shopsEncountered']),
      tags: List<String>.from(json['tags'] ?? const []),
      pathPoints: (json['pathPoints'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (point) =>
                JourneyPathPoint.fromJson(Map<String, dynamic>.from(point)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'status': status,
      'type': type.name,
      'startLat': startLat,
      'startLng': startLng,
      'startName': startName,
      'startTimeDate': startTimeDate.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'shopsEncountered': shopsEncountered,
      'tags': tags,
      'pathPoints': pathPoints.map((point) => point.toJson()).toList(),
      if (endLat != null) 'endLat': endLat,
      if (endLng != null) 'endLng': endLng,
      if (endName != null) 'endName': endName,
      if (endTimeDate != null) 'endTimeDate': endTimeDate!.toIso8601String(),
    };
  }

  static JourneyType _parseType(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == JourneyType.destination.name.toLowerCase()) {
      return JourneyType.destination;
    }

    return JourneyType.freeRoam;
  }

  static DateTime? _parseDate(dynamic field) {
    if (field == null) return null;
    if (field is String) return DateTime.tryParse(field);
    if (field is int) return DateTime.fromMillisecondsSinceEpoch(field);
    return null;
  }

  static List<String> _parseEncounteredShops(dynamic field) {
    if (field is! List) {
      return const <String>[];
    }

    return field
        .map((entry) {
          if (entry is String) {
            return entry.trim();
          }

          if (entry is Map) {
            final data = Map<String, dynamic>.from(entry);
            return (data['shopName'] ??
                    data['name'] ??
                    data['ShopName'] ??
                    data['Name'] ??
                    data['shopId'] ??
                    data['ShopId'] ??
                    data['id'] ??
                    data['Id'] ??
                    '')
                .toString()
                .trim();
          }

          return entry?.toString().trim() ?? '';
        })
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}
