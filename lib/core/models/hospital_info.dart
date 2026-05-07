import 'package:incident_reporter/core/models/coordinates.dart';

class HospitalInfo {
  const HospitalInfo({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.facilityType,
    required this.waitTime,
    required this.occupancy,
  });

  final String id;
  final String name;
  final CoordinatesModel coordinates;
  final String? facilityType;
  final String? waitTime;
  final int? occupancy;

  factory HospitalInfo.fromJson(Map<String, dynamic> json) {
    return HospitalInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hospital',
      coordinates: CoordinatesModel.fromJson(
        (json['coordinates'] as Map<String, dynamic>?) ?? const {},
      ),
      facilityType: json['facilityType']?.toString(),
      waitTime: json['waitTime']?.toString(),
      occupancy: (json['occupancy'] as num?)?.toInt(),
    );
  }
}
