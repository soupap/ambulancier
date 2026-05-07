import 'package:incident_reporter/core/models/coordinates.dart';

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.ambulanceId,
    required this.hospitalId,
    required this.phone,
    required this.license,
    required this.station,
    required this.experience,
    required this.certifications,
    required this.rating,
    required this.totalMissions,
    required this.missionsThisMonth,
    required this.avatar,
    required this.currentLocation,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? ambulanceId;
  final String? hospitalId;
  final String? phone;
  final String? license;
  final String? station;
  final int? experience;
  final List<String> certifications;
  final double? rating;
  final int? totalMissions;
  final int? missionsThisMonth;
  final String? avatar;
  final CoordinatesModel? currentLocation;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown driver',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'DRIVER',
      status: json['status']?.toString() ?? 'Active',
      ambulanceId: json['ambulanceId']?.toString(),
      hospitalId: json['hospitalId']?.toString(),
      phone: json['phone']?.toString(),
      license: json['license']?.toString(),
      station: json['station']?.toString(),
      experience: (json['experience'] as num?)?.toInt(),
      certifications:
          ((json['certifications'] as List<dynamic>?) ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalMissions: (json['totalMissions'] as num?)?.toInt(),
      missionsThisMonth: (json['missionsThisMonth'] as num?)?.toInt(),
      avatar: json['avatar']?.toString(),
      currentLocation: json['currentLocation'] is Map<String, dynamic>
          ? CoordinatesModel.fromJson(
              json['currentLocation'] as Map<String, dynamic>)
          : null,
    );
  }
}
