import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/models/assignment_stage.dart';
import 'package:incident_reporter/screens/shell_controller.dart';
import 'package:incident_reporter/services/driver_app_controller.dart';
import 'package:latlong2/latlong.dart';

class DriverMapScreen extends StatelessWidget {
  const DriverMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DriverAppController.instance;
    final shellController = Get.find<ShellController>();
    final mapController = MapController();

    return Obx(() {
      final assignment = controller.assignment;
      final hospital = controller.hospital;
      final route = controller.activeRoute;
      final currentLocation = controller.currentLocation;
      final center = currentLocation ??
          (assignment != null
              ? LatLng(
                  assignment.route.destination.lat,
                  assignment.route.destination.lng,
                )
              : const LatLng(36.8065, 10.1815));

      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14,
                      maxZoom: 18,
                      minZoom: 4,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.incident_reporter',
                      ),
                      if (route != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: route.points,
                              color: const Color(0xFF2575FC),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (assignment != null)
                            Marker(
                              point: LatLng(
                                assignment.route.destination.lat,
                                assignment.route.destination.lng,
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.person_pin_circle,
                                size: 42,
                                color: Color(0xFF2F80ED),
                              ),
                            ),
                          if (hospital != null)
                            Marker(
                              point: LatLng(
                                hospital.coordinates.lat,
                                hospital.coordinates.lng,
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.local_hospital,
                                size: 40,
                                color: Color(0xFFE14D5A),
                              ),
                            ),
                          if (currentLocation != null)
                            Marker(
                              point: currentLocation,
                              width: 54,
                              height: 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFDA3E52),
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emergency,
                                  color: Color(0xFFDA3E52),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 22,
                left: 22,
                right: 22,
                child: _TopBar(
                  onRefresh: controller.refreshAll,
                  onCenter: () {
                    final location = controller.currentLocation;
                    if (location != null) {
                      mapController.move(location, 15.5);
                    }
                  },
                  isTracking: controller.isTracking,
                  onToggleTracking: controller.toggleTracking,
                ),
              ),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (assignment == null && !controller.isLoading)
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment_late_outlined, size: 42),
                          const SizedBox(height: 12),
                          const Text(
                            'No active dispatch assignment',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.errorMessage ??
                                'Refresh after dispatch assigns your ambulance.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: controller.refreshAll,
                            child: const Text('Refresh assignment'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (assignment != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _CollapsibleMissionPanel(
                      expanded: shellController.missionPanelExpanded.value,
                      onToggle: shellController.toggleMissionPanel,
                      incidentTitle: assignment.incidentTitle,
                      hospitalName: assignment.hospitalName,
                      dispatcher: assignment.dispatcher ?? 'Dispatch Center',
                      notes: assignment.notes,
                      stage: controller.missionStage,
                      etaMinutes: route?.durationMinutes,
                      distanceKm: route?.distanceKm,
                      nextHint: route?.nextHint,
                      errorMessage: controller.errorMessage,
                      onAdvance: controller.advanceMissionStage,
                      onReload: controller.refreshAll,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onRefresh,
    required this.onCenter,
    required this.isTracking,
    required this.onToggleTracking,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onCenter;
  final bool isTracking;
  final Future<void> Function() onToggleTracking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.route, color: Color(0xFFDA3E52)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ambulancier live route',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MiniAction(icon: Icons.refresh, onTapAsync: onRefresh),
        const SizedBox(width: 8),
        _MiniAction(icon: Icons.my_location, onTap: onCenter),
        const SizedBox(width: 8),
        _MiniAction(
          icon: isTracking ? Icons.pause_circle : Icons.play_circle,
          onTapAsync: onToggleTracking,
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, this.onTap, this.onTapAsync});

  final IconData icon;
  final VoidCallback? onTap;
  final Future<void> Function()? onTapAsync;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          if (onTapAsync != null) {
            await onTapAsync!.call();
          } else {
            onTap?.call();
          }
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: const Color(0xFF243B55)),
        ),
      ),
    );
  }
}

class _CollapsibleMissionPanel extends StatelessWidget {
  const _CollapsibleMissionPanel({
    required this.expanded,
    required this.onToggle,
    required this.incidentTitle,
    required this.hospitalName,
    required this.dispatcher,
    required this.notes,
    required this.stage,
    required this.etaMinutes,
    required this.distanceKm,
    required this.nextHint,
    required this.errorMessage,
    required this.onAdvance,
    required this.onReload,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String incidentTitle;
  final String hospitalName;
  final String dispatcher;
  final String? notes;
  final AssignmentStage stage;
  final double? etaMinutes;
  final double? distanceKm;
  final String? nextHint;
  final String? errorMessage;
  final Future<void> Function() onAdvance;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6EA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          stage.label.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFDA3E52),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          incidentTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (etaMinutes != null)
                        Text(
                          '${etaMinutes!.round()} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2575FC),
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: expanded ? 0.0 : 0.5,
                        duration: const Duration(milliseconds: 260),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black45,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: _MissionPanelContent(
              incidentTitle: incidentTitle,
              hospitalName: hospitalName,
              dispatcher: dispatcher,
              notes: notes,
              stage: stage,
              etaMinutes: etaMinutes,
              distanceKm: distanceKm,
              nextHint: nextHint,
              errorMessage: errorMessage,
              onAdvance: onAdvance,
              onReload: onReload,
            ),
            secondChild: const SizedBox(width: double.infinity, height: 4),
          ),
        ],
      ),
    );
  }
}

class _MissionPanelContent extends StatelessWidget {
  const _MissionPanelContent({
    required this.incidentTitle,
    required this.hospitalName,
    required this.dispatcher,
    required this.notes,
    required this.stage,
    required this.etaMinutes,
    required this.distanceKm,
    required this.nextHint,
    required this.errorMessage,
    required this.onAdvance,
    required this.onReload,
  });

  final String incidentTitle;
  final String hospitalName;
  final String dispatcher;
  final String? notes;
  final AssignmentStage stage;
  final double? etaMinutes;
  final double? distanceKm;
  final String? nextHint;
  final String? errorMessage;
  final Future<void> Function() onAdvance;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  stage.label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFDA3E52),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (etaMinutes != null)
                _MetricChip(label: 'ETA', value: '${etaMinutes!.round()} min'),
              const SizedBox(width: 8),
              if (distanceKm != null)
                _MetricChip(
                  label: 'DIST',
                  value: '${distanceKm!.toStringAsFixed(1)} km',
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            incidentTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.local_hospital,
            label: 'Hospital',
            value: hospitalName,
          ),
          _InfoRow(
            icon: Icons.support_agent,
            label: 'Dispatcher',
            value: dispatcher,
          ),
          if (notes != null && notes!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.sticky_note_2_outlined,
              label: 'Notes',
              value: notes!.trim(),
            ),
          if (nextHint != null && nextHint!.isNotEmpty)
            _InfoRow(
              icon: Icons.turn_right,
              label: 'Next turn',
              value: nextHint!,
            ),
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAdvance,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(stage.primaryActionLabel),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onReload,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                child: const Text('Reload'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF486581)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
