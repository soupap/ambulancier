import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/mission_state.dart';
import '../models/route_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import 'mission_status_screen.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const double _routeRefreshDistanceMeters = 20;
  static const Duration _routeMinInterval = Duration(seconds: 4);

  static const List<LatLng> _missionCandidates = [
    LatLng(48.8566, 2.3522),
    LatLng(48.8621, 2.3389),
    LatLng(48.8519, 2.3561),
    LatLng(48.8479, 2.3700),
  ];

  late final AnimatedMapController _animatedMapController;
  late final AnimationController _markerAnimationController;

  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final Distance _distanceCalc = const Distance();
  final Random _random = Random();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _missionAssignmentTimer;
  LatLngTween? _markerTween;

  LatLng? _rawAmbulanceLocation;
  LatLng? _animatedAmbulanceLocation;
  LatLng? _patientLocation;
  RouteModel? _currentRoute;

  LatLng? _lastRouteAnchor;
  DateTime? _lastRouteRequestAt;

  MissionState _missionState = MissionState.assigned;

  bool _isTracking = false;
  bool _isFetchingRoute = false;
  bool _missionAssigned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onMarkerAnimationTick);

    _initializeLocation();
    _simulateMissionAssignment();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _missionAssignmentTimer?.cancel();
    _markerAnimationController
      ..removeListener(_onMarkerAnimationTick)
      ..dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  void _onMarkerAnimationTick() {
    if (!mounted || _markerTween == null) {
      return;
    }

    final value = _markerTween!.transform(_markerAnimationController.value);
    setState(() {
      _animatedAmbulanceLocation = value;
    });
  }

  Future<void> _initializeLocation() async {
    try {
      await _locationService.ensurePermission();
      final position = await _locationService.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = null;
        _rawAmbulanceLocation = current;
        _animatedAmbulanceLocation = current;
      });

      _animatedMapController.animateTo(dest: current, zoom: 15.5);
      await _updateRouteIfNeeded(current, force: true);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _simulateMissionAssignment() async {
    _missionAssignmentTimer?.cancel();
    _missionAssignmentTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _missionAssigned) {
        return;
      }

      final candidate =
          _missionCandidates[_random.nextInt(_missionCandidates.length)];

      setState(() {
        _missionAssigned = true;
        _missionState = MissionState.assigned;
        _patientLocation = candidate;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('New mission assigned')));

      final current = _rawAmbulanceLocation;
      if (current != null) {
        _updateRouteIfNeeded(current, force: true);
      }
    });
  }

  Future<void> _startTracking() async {
    if (_isTracking) {
      return;
    }

    try {
      await _locationService.ensurePermission();

      _positionSubscription = _locationService.getPositionStream().listen(
        (position) {
          final current = LatLng(position.latitude, position.longitude);
          _handleLocationUpdate(current);
        },
        onError: (error) {
          _setError(error.toString());
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isTracking = true;
        _errorMessage = null;
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isTracking = false;
    });
  }

  void _handleLocationUpdate(LatLng current) {
    if (!mounted) {
      return;
    }

    final previous = _rawAmbulanceLocation;
    if (previous == null) {
      setState(() {
        _rawAmbulanceLocation = current;
        _animatedAmbulanceLocation = current;
        _errorMessage = null;
      });
      _moveMapSmoothly(current);
      _updateRouteIfNeeded(current, force: true);
      return;
    }

    final moved = _metersBetween(previous, current);
    if (moved < 2) {
      return;
    }

    setState(() {
      _rawAmbulanceLocation = current;
      _errorMessage = null;
    });

    _animateAmbulanceMarker(previous, current, movedMeters: moved);
    _moveMapSmoothly(current);
    _updateRouteIfNeeded(current);
    _updateMissionProgress(current);
  }

  void _animateAmbulanceMarker(
    LatLng from,
    LatLng to, {
    required double movedMeters,
  }) {
    final durationMs = movedMeters.clamp(350, 1100).toInt();

    _markerTween = LatLngTween(begin: from, end: to);
    _markerAnimationController.duration = Duration(milliseconds: durationMs);
    _markerAnimationController
      ..reset()
      ..forward();
  }

  void _moveMapSmoothly(LatLng target) {
    final zoom = _animatedMapController.mapController.camera.zoom;
    _animatedMapController.animateTo(
      dest: target,
      zoom: zoom,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _updateRouteIfNeeded(
    LatLng current, {
    bool force = false,
  }) async {
    final patient = _patientLocation;
    if (patient == null || _isFetchingRoute) {
      return;
    }

    if (!force) {
      final anchor = _lastRouteAnchor;
      if (anchor != null) {
        final movedSinceLastFetch = _metersBetween(anchor, current);
        if (movedSinceLastFetch <= _routeRefreshDistanceMeters) {
          return;
        }
      }

      final lastRequestAt = _lastRouteRequestAt;
      if (lastRequestAt != null &&
          DateTime.now().difference(lastRequestAt) < _routeMinInterval) {
        return;
      }
    }

    _isFetchingRoute = true;
    _lastRouteRequestAt = DateTime.now();

    try {
      final route = await _routeService.fetchRoute(
        start: current,
        end: patient,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentRoute = route;
        _lastRouteAnchor = current;
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _updateMissionProgress(LatLng current) {
    final patient = _patientLocation;
    if (patient == null) {
      return;
    }

    final metersToPatient = _metersBetween(current, patient);
    if (_missionState == MissionState.enRoute && metersToPatient < 40) {
      setState(() {
        _missionState = MissionState.arrived;
      });
    }
  }

  void _setError(String message) {
    if (!mounted || _errorMessage == message) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });
  }

  void _recenterMap() {
    final current = _animatedAmbulanceLocation;
    if (current == null) {
      return;
    }

    _animatedMapController.animateTo(
      dest: current,
      zoom: 16,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );
  }

  void _onMissionPrimaryAction() {
    switch (_missionState) {
      case MissionState.assigned:
        setState(() {
          _missionState = MissionState.enRoute;
        });
        return;
      case MissionState.enRoute:
        setState(() {
          _missionState = MissionState.arrived;
        });
        return;
      case MissionState.arrived:
        setState(() {
          _missionState = MissionState.pickedUp;
        });
        return;
      case MissionState.pickedUp:
        setState(() {
          _missionState = MissionState.completed;
        });
        _openMissionStatusScreen();
        return;
      case MissionState.completed:
        _openMissionStatusScreen();
        return;
    }
  }

  void _openMissionStatusScreen() {
    final route = _currentRoute;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => MissionStatusScreen(
              missionState: _missionState,
              patientName: 'John Doe',
              destinationName: 'City General Hospital',
              totalDistanceKm: route?.distanceKm ?? 0,
              totalDurationMin: route?.durationMinutes ?? 0,
              nextHint: route?.nextHint,
            ),
      ),
    );
  }

  String _primaryActionLabel() {
    switch (_missionState) {
      case MissionState.assigned:
        return 'Start Route';
      case MissionState.enRoute:
        return 'Arrived';
      case MissionState.arrived:
        return 'Pick Up Patient';
      case MissionState.pickedUp:
        return 'Go To Hospital';
      case MissionState.completed:
        return 'Ready For Next Mission';
    }
  }

  String _statusLabel() {
    if (_missionState == MissionState.enRoute) {
      return 'EN ROUTE';
    }
    return _missionState.title;
  }

  String _formatEta(double? minutes) {
    if (minutes == null || minutes <= 0) {
      return '--';
    }

    if (minutes < 60) {
      return '${minutes.round()} min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = (minutes % 60).round();
    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDistance(double? km) {
    if (km == null || km <= 0) {
      return '--';
    }

    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)}k km';
    }

    if (km >= 100) {
      return '${km.toStringAsFixed(0)} km';
    }

    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final route = _currentRoute;
    final ambulance = _animatedAmbulanceLocation;
    final patient = _patientLocation;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final uiScale =
        screenWidth < 640
            ? 1.0
            : screenWidth < 1000
            ? 1.08
            : 1.24;
    final cardScale =
        screenWidth < 640
            ? 1.0
            : screenWidth < 1000
            ? 0.95
            : 0.82;
    final bottomBarScale = screenWidth < 700 ? 0.96 : 1.02;
    final contentMaxWidth =
        screenWidth < 900 ? screenWidth - 24 : min(1180.0, screenWidth * 0.82);

    return Scaffold(
      backgroundColor: const Color(0xFF101826),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFF4F7FA)),
              child: Column(
                children: [
                  _TopMissionHeader(
                    statusLabel: _statusLabel(),
                    scale: uiScale,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _animatedMapController.mapController,
                            options: MapOptions(
                              initialCenter:
                                  ambulance ??
                                  patient ??
                                  const LatLng(48.8566, 2.3522),
                              initialZoom: 13,
                              minZoom: 4,
                              maxZoom: 18,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.ambulancier',
                              ),
                              if (route != null)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: route.points,
                                      strokeWidth: 5,
                                      color: const Color(0xFF3DD4FF),
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  if (patient != null)
                                    Marker(
                                      point: patient,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.person_pin_circle,
                                        size: 40,
                                        color: Color(0xFF217BFF),
                                      ),
                                    ),
                                  if (ambulance != null)
                                    Marker(
                                      point: ambulance,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.local_hospital,
                                        size: 40,
                                        color: Color(0xFFE94444),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.58),
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.white.withValues(alpha: 0.68),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14 * uiScale,
                          right: 14 * uiScale,
                          top: 10 * uiScale,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14 * uiScale,
                                  vertical: 8 * uiScale,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5B5B),
                                  borderRadius: BorderRadius.circular(
                                    24 * uiScale,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      size: 13 * uiScale,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6 * uiScale),
                                    Text(
                                      'HIGH PRIORITY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10 * uiScale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _StatBadge(
                                label: 'ETA',
                                value: _formatEta(route?.durationMinutes),
                                scale: uiScale,
                              ),
                              SizedBox(width: 8 * uiScale),
                              _StatBadge(
                                label: 'DIST',
                                value: _formatDistance(route?.distanceKm),
                                scale: uiScale,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 14 * uiScale,
                          top: 74 * uiScale,
                          child: Column(
                            children: [
                              _RoundControl(
                                icon: Icons.my_location,
                                onTap: _recenterMap,
                                scale: uiScale,
                              ),
                              SizedBox(height: 8 * uiScale),
                              _RoundControl(
                                icon:
                                    _isTracking
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                onTap:
                                    _isTracking
                                        ? _stopTracking
                                        : _startTracking,
                                scale: uiScale,
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentMaxWidth,
                            ),
                            child: _PatientCard(
                              nextHint: route?.nextHint,
                              missionState: _missionState,
                              errorMessage: _errorMessage,
                              onPrimaryAction: _onMissionPrimaryAction,
                              primaryActionLabel: _primaryActionLabel(),
                              scale: cardScale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BottomMenu(
                    onMissionsTap: _openMissionStatusScreen,
                    onProfileTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    scale: bottomBarScale,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _metersBetween(LatLng a, LatLng b) {
    return _distanceCalc.as(LengthUnit.Meter, a, b);
  }
}

class _TopMissionHeader extends StatelessWidget {
  const _TopMissionHeader({required this.statusLabel, required this.scale});

  final String statusLabel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: const Color(0xFF1E5CE4), size: 18 * scale),
          SizedBox(width: 10 * scale),
          Text(
            'MISSION STATUS',
            style: TextStyle(
              color: const Color(0xFF1E5CE4),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              fontSize: 13 * scale,
            ),
          ),
          const Spacer(),
          Text(
            statusLabel,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 11 * scale,
            ),
          ),
          SizedBox(width: 8 * scale),
          Icon(
            Icons.notifications_none,
            color: Colors.blueGrey.shade300,
            size: 18 * scale,
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.scale,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94 * scale,
      padding: EdgeInsets.fromLTRB(9 * scale, 7 * scale, 9 * scale, 7 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * scale,
              color: const Color(0xFF7A8798),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3 * scale),
          SizedBox(
            height: 20 * scale,
            child: Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 17 * scale,
                    color: const Color(0xFF1262D6),
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.onTap,
    required this.scale,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20 * scale),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * scale),
        onTap: onTap,
        child: SizedBox(
          width: 40 * scale,
          height: 40 * scale,
          child: Icon(icon, color: const Color(0xFF2E5BD8), size: 20 * scale),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.nextHint,
    required this.missionState,
    required this.errorMessage,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    required this.scale,
  });

  final String? nextHint;
  final MissionState missionState;
  final String? errorMessage;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final titleSize = max(9 * scale, 11.0);
    final nameSize = max(17 * scale, 18.0);
    final statusSize = max(9 * scale, 10.0);
    final destinationSize = max(15 * scale, 15.0);
    final hintSize = max(11 * scale, 12.0);
    final errorSize = max(10 * scale, 12.0);
    final buttonTextSize = max(14 * scale, 15.0);

    return Container(
      margin: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 12 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        8 * scale,
        14 * scale,
        8 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF1C70D8),
                  size: 22 * scale,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PATIENT IDENTITY',
                      style: TextStyle(
                        fontSize: titleSize,
                        color: Colors.black45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF21252A),
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      'RESPIRATORY DISTRESS',
                      style: TextStyle(
                        fontSize: statusSize,
                        color: const Color(0xFFD43C3C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40 * scale,
                height: 40 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  Icons.call,
                  color: const Color(0xFF535862),
                  size: 20 * scale,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  size: 18 * scale,
                  color: const Color(0xFF1D6EDA),
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    'City General Hospital',
                    style: TextStyle(
                      fontSize: destinationSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF353A45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (nextHint != null && nextHint!.isNotEmpty) ...[
            SizedBox(height: 6 * scale),
            Text(
              'Next: $nextHint',
              style: TextStyle(
                fontSize: hintSize,
                color: const Color(0xFF475B78),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (errorMessage != null) ...[
            SizedBox(height: 4 * scale),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: errorSize,
                color: const Color(0xFFE94444),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 8 * scale),
          SizedBox(
            width: double.infinity,
            height: 46 * scale,
            child: FilledButton(
              onPressed: onPrimaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1874D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14 * scale),
                ),
              ),
              child: Text(
                missionState == MissionState.completed
                    ? 'Ready For Next Mission'
                    : primaryActionLabel,
                style: TextStyle(
                  fontSize: buttonTextSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu({
    required this.onMissionsTap,
    required this.onProfileTap,
    required this.scale,
  });

  final VoidCallback onMissionsTap;
  final VoidCallback onProfileTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 26 * scale,
        vertical: 6 * scale,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomItem(
            icon: Icons.assignment_outlined,
            label: 'MISSIONS',
            active: false,
            onTap: onMissionsTap,
            scale: scale,
          ),
          _BottomItem(
            icon: Icons.map,
            label: 'MAP',
            active: true,
            onTap: () {},
            scale: scale,
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'PROFILE',
            active: false,
            onTap: onProfileTap,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 74 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30 * scale,
              height: 30 * scale,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE8F0FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 17 * scale,
                color:
                    active ? const Color(0xFF2B60E0) : const Color(0xFF98A4B8),
              ),
            ),
            SizedBox(height: 1 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 9 * scale,
                fontWeight: FontWeight.w700,
                color:
                    active ? const Color(0xFF2B60E0) : const Color(0xFF98A4B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
