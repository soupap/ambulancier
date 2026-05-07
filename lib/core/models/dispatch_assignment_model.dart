import 'package:incident_reporter/core/models/dispatch_assignment.dart';

class DispatchAssignmentModel {
  const DispatchAssignmentModel({
    required this.assignmentId,
    required this.incidentId,
    required this.incidentTitle,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverId,
    required this.driverName,
    required this.hospitalId,
    required this.hospitalName,
    required this.dispatcher,
    required this.notes,
    required this.vehicleStatus,
    required this.state,
    required this.dispatchedAt,
    required this.incidentTags,
    required this.route,
  });

  final String assignmentId;
  final String incidentId;
  final String incidentTitle;
  final String vehicleId;
  final String vehicleName;
  final String? driverId;
  final String? driverName;
  final String hospitalId;
  final String hospitalName;
  final String? dispatcher;
  final String? notes;
  final String vehicleStatus;
  final String state;
  final String? dispatchedAt;
  final List<String> incidentTags;
  final DispatchRoute route;

  factory DispatchAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DispatchAssignmentModel(
      assignmentId: json['assignmentId']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      incidentTitle: json['incidentTitle']?.toString() ?? 'Emergency dispatch',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? '',
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString(),
      hospitalId: json['hospitalId']?.toString() ?? '',
      hospitalName: json['hospitalName']?.toString() ?? 'Hospital',
      dispatcher: json['dispatcher']?.toString(),
      notes: json['notes']?.toString(),
      vehicleStatus: json['vehicleStatus']?.toString() ?? 'busy',
      state: json['state']?.toString() ?? 'Dispatched',
      dispatchedAt: json['dispatchedAt']?.toString(),
      incidentTags:
          ((json['incidentTags'] as List<dynamic>?) ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      route: DispatchRoute.fromJson(
        (json['route'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
