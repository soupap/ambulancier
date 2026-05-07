import 'package:incident_reporter/core/api/api_client.dart';
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/models/coordinates.dart';
import 'package:incident_reporter/core/models/dispatch_assignment_model.dart';
import 'package:incident_reporter/core/models/driver_profile.dart';
import 'package:incident_reporter/core/models/hospital_info.dart';
import 'package:incident_reporter/core/models/vehicle_info.dart';

class DriverBackendService {
  DriverBackendService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;
  List<HospitalInfo>? _hospitalCache;

  Future<DriverProfile> fetchCurrentDriver() async {
    final decoded =
        await _client.getJson('${AppConfig.apiBaseUrl}/api/users/me');
    return DriverProfile.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<DispatchAssignmentModel>> fetchAssignmentsByAmbulance(
      String ambulanceId) async {
    final decoded = await _client.getJson(
      '${AppConfig.apiBaseUrl}/api/dispatch/assignments/ambulance/$ambulanceId',
    );
    return (decoded as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DispatchAssignmentModel.fromJson)
        .toList();
  }

  Future<VehicleInfo?> fetchVehicle(String vehicleId) async {
    final decoded =
        await _client.getJson('${AppConfig.apiBaseUrl}/api/vehicles');
    final list = (decoded as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(VehicleInfo.fromJson);

    for (final vehicle in list) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  Future<HospitalInfo?> fetchHospitalById(String hospitalId) async {
    final hospitals = await fetchHospitals();
    for (final hospital in hospitals) {
      if (hospital.id == hospitalId) {
        return hospital;
      }
    }
    return null;
  }

  Future<List<HospitalInfo>> fetchHospitals({bool forceRefresh = false}) async {
    if (!forceRefresh && _hospitalCache != null) {
      return _hospitalCache!;
    }

    final decoded =
        await _client.getJson('${AppConfig.apiBaseUrl}/api/hospitals');
    _hospitalCache = (decoded as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(HospitalInfo.fromJson)
        .toList();
    return _hospitalCache!;
  }

  Future<void> updateDriverStatus(String driverId, String status) async {
    await _client.patchJson(
      '${AppConfig.apiBaseUrl}/api/drivers/$driverId/status',
      {'status': status},
    );
  }

  Future<void> updateDriverLocation(
      String driverId, CoordinatesModel location) async {
    await _client.postJson(
      '${AppConfig.apiBaseUrl}/api/drivers/$driverId/location',
      {
        'latitude': location.lat,
        'longitude': location.lng,
      },
    );
  }

  Future<void> updateAssignmentState(String assignmentId, String state) async {
    await _client.putJson(
      '${AppConfig.apiBaseUrl}/api/dispatch/assignments/$assignmentId/state/$state',
      {},
    );
  }
}
