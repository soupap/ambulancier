import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<void> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException();
    }
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    );
  }
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() => 'Location permission denied.';
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() => 'Location services are disabled.';
}
