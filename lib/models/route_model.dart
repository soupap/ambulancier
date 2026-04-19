import 'package:latlong2/latlong.dart';

class RouteModel {
  const RouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.nextHint,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String? nextHint;

  double get distanceKm => distanceMeters / 1000;
  double get durationMinutes => durationSeconds / 60;
}
