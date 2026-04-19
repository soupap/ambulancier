import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';

class RouteService {
  static const String _baseUrl = 'http://router.project-osrm.org';

  Future<RouteModel> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw RouteServiceException(
        'OSRM request failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;

    if (routes == null || routes.isEmpty) {
      throw const RouteServiceException('No route found from OSRM.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;

    if (coordinates == null || coordinates.isEmpty) {
      throw const RouteServiceException('Invalid route geometry from OSRM.');
    }

    final points =
        coordinates.map((item) {
          final pair = item as List<dynamic>;
          final lon = (pair[0] as num).toDouble();
          final lat = (pair[1] as num).toDouble();
          return LatLng(lat, lon);
        }).toList();

    final nextHint = _parseNextHint(route);

    return RouteModel(
      points: points,
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      nextHint: nextHint,
    );
  }

  String? _parseNextHint(Map<String, dynamic> route) {
    final legs = route['legs'] as List<dynamic>?;
    final firstLeg =
        legs != null && legs.isNotEmpty
            ? legs.first as Map<String, dynamic>
            : null;
    final steps = firstLeg?['steps'] as List<dynamic>?;
    final firstStep =
        steps != null && steps.isNotEmpty
            ? steps.first as Map<String, dynamic>
            : null;

    final name = (firstStep?['name'] as String?)?.trim();
    final maneuver = firstStep?['maneuver'] as Map<String, dynamic>?;
    final modifier = (maneuver?['modifier'] as String?)?.trim();
    final type = (maneuver?['type'] as String?)?.trim();

    if (modifier != null && modifier.isNotEmpty) {
      final verb = modifier[0].toUpperCase() + modifier.substring(1);
      if (name != null && name.isNotEmpty) {
        return '$verb on $name';
      }
      return verb;
    }

    if (type != null && type.isNotEmpty) {
      final label = type[0].toUpperCase() + type.substring(1);
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
