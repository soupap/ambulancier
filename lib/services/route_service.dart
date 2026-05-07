import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/models/route_model.dart';
import 'package:latlong2/latlong.dart';

class RouteService {
  Future<RouteModel> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.osrmBaseUrl}/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw RouteServiceException(
        'Routing service returned ${response.statusCode}.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const RouteServiceException('No route found.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    final points = coordinates
        .map((item) => item as List<dynamic>)
        .map((pair) =>
            LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble()))
        .toList();

    return RouteModel(
      points: points,
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      nextHint: _nextHint(route),
    );
  }

  String? _nextHint(Map<String, dynamic> route) {
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) {
      return null;
    }

    final steps =
        (legs.first as Map<String, dynamic>)['steps'] as List<dynamic>?;
    if (steps == null || steps.isEmpty) {
      return null;
    }

    final first = steps.first as Map<String, dynamic>;
    final name = first['name']?.toString().trim();
    final maneuver = first['maneuver'] as Map<String, dynamic>?;
    final modifier = maneuver?['modifier']?.toString().trim();
    final type = maneuver?['type']?.toString().trim();

    if (modifier != null && modifier.isNotEmpty) {
      final label = '${modifier[0].toUpperCase()}${modifier.substring(1)}';
      return name != null && name.isNotEmpty ? '$label on $name' : label;
    }

    if (type != null && type.isNotEmpty) {
      final label = '${type[0].toUpperCase()}${type.substring(1)}';
      return name != null && name.isNotEmpty ? '$label on $name' : label;
    }

    return null;
  }
}

class RouteServiceException implements Exception {
  const RouteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
