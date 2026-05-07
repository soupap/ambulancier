import 'package:incident_reporter/core/models/coordinates.dart';

class VehicleInfo {
  const VehicleInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.location,
    required this.crew,
    required this.lastUpdate,
    required this.equipment,
  });

  final String id;
  final String name;
  final String status;
  final String type;
  final CoordinatesModel location;
  final List<String> crew;
  final String? lastUpdate;
  final List<dynamic> equipment;

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown vehicle',
      status: json['status']?.toString() ?? 'available',
      type: json['type']?.toString() ?? 'ambulance',
      location: CoordinatesModel.fromJson(
        (json['location'] as Map<String, dynamic>?) ?? const {},
      ),
      crew: ((json['crew'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      lastUpdate: json['lastUpdate']?.toString(),
      equipment: (json['equipment'] as List<dynamic>?) ?? const <dynamic>[],
    );
  }

  VehicleInfo copyWith({
    String? status,
    CoordinatesModel? location,
    String? lastUpdate,
  }) {
    return VehicleInfo(
      id: id,
      name: name,
      status: status ?? this.status,
      type: type,
      location: location ?? this.location,
      crew: crew,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      equipment: equipment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'type': type,
        'location': location.toJson(),
        'crew': crew,
        'lastUpdate': lastUpdate,
        'equipment': equipment,
      };
}
