// No imports needed for standard types

enum JourneyType { destination, freeRoam }

class JourneyModel {
  final String? id;
  final String userId;
  final String userEmail;
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

  JourneyModel({
    this.id,
    required this.userId,
    required this.userEmail,
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
  });

  factory JourneyModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return JourneyModel(
      id: id ?? json['id']?.toString() ?? json['journeyId']?.toString(),
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail'] ?? '',
      type: JourneyType.values.byName(json['type'] ?? 'freeRoam'),
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0.0,
      startLng: (json['startLng'] as num?)?.toDouble() ?? 0.0,
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: (json['endLng'] as num?)?.toDouble(),
      startName: json['startName'],
      endName: json['endName'],
      startTimeDate: _parseDate(json['startTimeDate'] ?? json['startTime']) ?? DateTime.now(),
      endTimeDate: _parseDate(json['endTimeDate'] ?? json['endTime']),
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      shopsEncountered: List<String>.from(json['shopsEncountered'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'type': type.name,
      'startLat': startLat,
      'startLng': startLng,
      'startName': startName,
      'startTimeDate': startTimeDate.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'shopsEncountered': shopsEncountered,
      'tags': tags,
      if (endLat != null) 'endLat': endLat,
      if (endLng != null) 'endLng': endLng,
      if (endName != null) 'endName': endName,
      if (endTimeDate != null) 'endTimeDate': endTimeDate!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic field) {
    if (field == null) return null;
    if (field is String) return DateTime.tryParse(field);
    if (field is int) return DateTime.fromMillisecondsSinceEpoch(field);
    return null;
  }
}
