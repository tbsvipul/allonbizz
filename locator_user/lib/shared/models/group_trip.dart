import 'package:equatable/equatable.dart';

/// Model for a shared navigation session among multiple users.
class GroupTrip extends Equatable {
  final String id;
  final String hostId;
  final String routeId;
  final String destinationName;
  final List<GroupParticipant> participants;
  final bool isActive;
  final DateTime createdAt;

  const GroupTrip({
    required this.id,
    required this.hostId,
    required this.routeId,
    required this.destinationName,
    required this.participants,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    hostId,
    routeId,
    destinationName,
    participants,
    isActive,
    createdAt,
  ];

  GroupTrip copyWith({
    String? id,
    String? hostId,
    String? routeId,
    String? destinationName,
    List<GroupParticipant>? participants,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GroupTrip(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      routeId: routeId ?? this.routeId,
      destinationName: destinationName ?? this.destinationName,
      participants: participants ?? this.participants,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupParticipant extends Equatable {
  final String userId;
  final String displayName;
  final double? latitude;
  final double? longitude;
  final bool isArrived;

  const GroupParticipant({
    required this.userId,
    required this.displayName,
    this.latitude,
    this.longitude,
    this.isArrived = false,
  });

  @override
  List<Object?> get props => [
    userId,
    displayName,
    latitude,
    longitude,
    isArrived,
  ];

  GroupParticipant copyWith({
    String? userId,
    String? displayName,
    double? latitude,
    double? longitude,
    bool? isArrived,
  }) {
    return GroupParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isArrived: isArrived ?? this.isArrived,
    );
  }
}
