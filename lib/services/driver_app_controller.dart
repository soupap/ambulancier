import 'dart:async';

import 'package:get/get.dart';
import 'package:incident_reporter/app/routes/app_routes.dart';
import 'package:incident_reporter/core/models/coordinates.dart';
import 'package:incident_reporter/core/models/dispatch_assignment_model.dart';
import 'package:incident_reporter/core/models/driver_notification.dart';
import 'package:incident_reporter/core/models/driver_profile.dart';
import 'package:incident_reporter/core/models/hospital_info.dart';
import 'package:incident_reporter/core/models/vehicle_info.dart';
import 'package:incident_reporter/core/services/auth_service.dart';
import 'package:incident_reporter/models/assignment_stage.dart';
import 'package:incident_reporter/models/route_model.dart';
import 'package:incident_reporter/screens/shell_controller.dart';
import 'package:incident_reporter/services/dispatch_socket_service.dart';
import 'package:incident_reporter/services/driver_backend_service.dart';
import 'package:incident_reporter/services/location_service.dart';
import 'package:incident_reporter/services/route_service.dart';
import 'package:latlong2/latlong.dart';

class DriverAppController extends GetxController {
  static DriverAppController get instance => Get.find<DriverAppController>();

  final AuthService _authService = AuthService.instance;
  final DriverBackendService _backendService = DriverBackendService();
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final DispatchSocketService _socketService = DispatchSocketService();
  final ShellController _shellController = Get.find<ShellController>();

  StreamSubscription? _positionSubscription;
  DateTime? _lastLocationSyncAt;
  Worker? _authWorker;

  final _bootstrapping = true.obs;
  final _loading = false.obs;
  final _tracking = false.obs;
  final _routeLoading = false.obs;
  final _errorMessage = RxnString();
  final _sessionToken = RxnString();

  final _profile = Rxn<DriverProfile>();
  final _vehicle = Rxn<VehicleInfo>();
  final _assignment = Rxn<DispatchAssignmentModel>();
  final _hospital = Rxn<HospitalInfo>();
  final _activeRoute = Rxn<RouteModel>();
  final _currentLocation = Rxn<LatLng>();
  final _missionStage = AssignmentStage.cancelled.obs;
  final _notifications = <DriverNotification>[].obs;

  bool get isBootstrapping => _bootstrapping.value;
  bool get isLoading => _loading.value;
  bool get isTracking => _tracking.value;
  bool get isRouteLoading => _routeLoading.value;
  bool get isLoggingIn => _authService.isAuthenticating.value;
  bool get isAuthenticated => _authService.isAuthenticated.value;
  String? get errorMessage => _errorMessage.value;
  String? get sessionToken => _sessionToken.value;
  DriverProfile? get profile => _profile.value;
  VehicleInfo? get vehicle => _vehicle.value;
  DispatchAssignmentModel? get assignment => _assignment.value;
  HospitalInfo? get hospital => _hospital.value;
  RouteModel? get activeRoute => _activeRoute.value;
  LatLng? get currentLocation => _currentLocation.value;
  AssignmentStage get missionStage => _missionStage.value;
  List<DriverNotification> get notifications =>
      List.unmodifiable(_notifications);

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<bool>(_authService.isAuthenticated, _handleAuthState);
  }

  @override
  void onReady() {
    super.onReady();
    initialize();
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    _positionSubscription?.cancel();
    _socketService.disconnect();
    super.onClose();
  }

  Future<void> initialize() async {
    await _authService.init();
    if (isAuthenticated) {
      await loadDashboard();
    } else {
      _sessionToken.value = null;
    }
    _bootstrapping.value = false;
    _syncNavigation();
  }

  Future<bool> login() async {
    _errorMessage.value = null;
    final success = await _authService.login();
    if (success) {
      _shellController.reset();
      await _loadSessionToken();
      await loadDashboard();
    }
    return success;
  }

  Future<void> logout() async {
    await _resetSessionState();
    await _authService.logout();
  }

  Future<void> loadDashboard() async {
    if (!isAuthenticated) {
      return;
    }

    _loading.value = true;
    _errorMessage.value = null;

    try {
      await _loadSessionToken();
      _profile.value = await _backendService.fetchCurrentDriver();
      final ambulanceId = _profile.value?.ambulanceId;
      if (ambulanceId != null && ambulanceId.isNotEmpty) {
        _vehicle.value = await _backendService.fetchVehicle(ambulanceId);
        final assignments =
            await _backendService.fetchAssignmentsByAmbulance(ambulanceId);
        _assignment.value = assignments.isNotEmpty ? assignments.first : null;
        _hospital.value = _assignment.value == null
            ? null
            : await _backendService
                .fetchHospitalById(_assignment.value!.hospitalId);
        _missionStage.value = _assignment.value == null
            ? AssignmentStage.cancelled
            : AssignmentStage.assigned;
      } else {
        _vehicle.value = null;
        _assignment.value = null;
        _hospital.value = null;
        _missionStage.value = AssignmentStage.cancelled;
      }

      _seedCurrentLocation();
      await _refreshRoute();
      await _startTracking(auto: true);
      await _connectSocket();
    } catch (error) {
      _errorMessage.value = error.toString();
    } finally {
      _loading.value = false;
    }
  }

  Future<void> refreshAll() => loadDashboard();

  Future<void> toggleTracking() async {
    if (_tracking.value) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _tracking.value = false;
      return;
    }

    await _startTracking(auto: false);
  }

  Future<void> advanceMissionStage() async {
    if (_assignment.value == null || _profile.value == null) {
      await loadDashboard();
      return;
    }

    _missionStage.value = switch (_missionStage.value) {
      AssignmentStage.assigned => AssignmentStage.enRoute,
      AssignmentStage.enRoute => AssignmentStage.arrived,
      AssignmentStage.arrived => AssignmentStage.completed,
      AssignmentStage.completed => AssignmentStage.completed,
      AssignmentStage.cancelled => AssignmentStage.assigned,
    };

    try {
      final assignment = _assignment.value;
      if (assignment != null) {
        await _backendService.updateAssignmentState(
          assignment.assignmentId,
          _missionStage.value.assignmentState,
        );
      }
      await _syncVehicleStatus();
      await _refreshRoute();
    } catch (error) {
      _errorMessage.value = error.toString();
    }
  }

  Future<void> _startTracking({required bool auto}) async {
    try {
      await _locationService.ensurePermission();
      final position = await _locationService.getCurrentPosition();
      _currentLocation.value = LatLng(position.latitude, position.longitude);
      await _syncCurrentLocation();
      await _refreshRoute();

      await _positionSubscription?.cancel();
      _positionSubscription =
          _locationService.getPositionStream().listen((position) async {
        _currentLocation.value = LatLng(position.latitude, position.longitude);
        await _syncCurrentLocation();
        await _refreshRoute();
      });
      _tracking.value = true;
    } catch (error) {
      _errorMessage.value = error.toString();
    }
  }

  Future<void> _refreshRoute() async {
    final current = _currentLocation.value;
    final target = _currentTarget;
    if (current == null ||
        target == null ||
        _missionStage.value == AssignmentStage.completed) {
      _activeRoute.value = null;
      return;
    }

    _routeLoading.value = true;

    try {
      _activeRoute.value =
          await _routeService.fetchRoute(start: current, end: target);
    } catch (error) {
      _errorMessage.value = error.toString();
    } finally {
      _routeLoading.value = false;
    }
  }

  Future<void> _connectSocket() async {
    final ambulanceId = _profile.value?.ambulanceId;
    if (ambulanceId == null || ambulanceId.isEmpty) {
      return;
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      return;
    }

    _socketService.connect(
      token: token,
      ambulanceId: ambulanceId,
      onAssignment: (assignment) async {
        _assignment.value = assignment;
        _hospital.value =
            await _backendService.fetchHospitalById(assignment.hospitalId);
        _missionStage.value = AssignmentStage.assigned;
        _notifications.insert(
          0,
          DriverNotification(
            title: 'New dispatch assigned',
            message:
                '${assignment.incidentTitle} -> ${assignment.hospitalName}',
            timestamp: DateTime.now(),
          ),
        );
        await _refreshRoute();
      },
      onError: (message) {
        _errorMessage.value = message;
      },
    );
  }

  Future<void> _syncCurrentLocation() async {
    if (_profile.value == null || _currentLocation.value == null) {
      return;
    }

    final now = DateTime.now();
    if (_lastLocationSyncAt != null &&
        now.difference(_lastLocationSyncAt!) < const Duration(seconds: 8)) {
      return;
    }
    _lastLocationSyncAt = now;

    final coordinates = CoordinatesModel(
      lat: _currentLocation.value!.latitude,
      lng: _currentLocation.value!.longitude,
    );

    try {
      await _backendService.updateDriverLocation(
          _profile.value!.id, coordinates);
    } catch (error) {
      _errorMessage.value = error.toString();
    }
  }

  Future<void> _syncVehicleStatus() async {
    // Logic currently commented out by user in previous edits
  }

  void _seedCurrentLocation() {
    if (_currentLocation.value != null) {
      return;
    }

    if (_profile.value?.currentLocation != null) {
      _currentLocation.value = LatLng(
        _profile.value!.currentLocation!.lat,
        _profile.value!.currentLocation!.lng,
      );
      return;
    }

    if (_vehicle.value != null) {
      _currentLocation.value =
          LatLng(_vehicle.value!.location.lat, _vehicle.value!.location.lng);
    }
  }

  LatLng? get _currentTarget {
    if (_assignment.value == null) {
      return null;
    }

    if (_missionStage.value == AssignmentStage.arrived ||
        _missionStage.value == AssignmentStage.completed) {
      if (_hospital.value == null) {
        return null;
      }
      return LatLng(
          _hospital.value!.coordinates.lat, _hospital.value!.coordinates.lng);
    }

    return LatLng(
      _assignment.value!.route.destination.lat,
      _assignment.value!.route.destination.lng,
    );
  }

  Future<void> _loadSessionToken() async {
    _sessionToken.value = await _authService.getValidToken();
  }

  Future<void> _resetSessionState() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _tracking.value = false;
    _socketService.disconnect();
    _profile.value = null;
    _vehicle.value = null;
    _assignment.value = null;
    _hospital.value = null;
    _activeRoute.value = null;
    _currentLocation.value = null;
    _missionStage.value = AssignmentStage.cancelled;
    _notifications.clear();
    _sessionToken.value = null;
    _shellController.reset();
  }

  void _handleAuthState(bool authenticated) {
    if (!authenticated) {
      unawaited(_resetSessionState());
    }

    if (_bootstrapping.value) {
      return;
    }

    _syncNavigation();
  }

  void _syncNavigation() {
    final targetRoute = isAuthenticated ? AppRoutes.shell : AppRoutes.login;

    if (Get.currentRoute == targetRoute) {
      return;
    }

    Get.offAllNamed<dynamic>(targetRoute);
  }
}
