import 'package:flutter/material.dart';

import '../models/mission_state.dart';
import 'profile_screen.dart';

class MissionStatusScreen extends StatelessWidget {
  const MissionStatusScreen({
    super.key,
    required this.missionState,
    required this.patientName,
    required this.destinationName,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    this.nextHint,
  });

  final MissionState missionState;
  final String patientName;
  final String destinationName;
  final double totalDistanceKm;
  final double totalDurationMin;
  final String? nextHint;

  @override
  Widget build(BuildContext context) {
    final isCompleted = missionState == MissionState.completed;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth < 700 ? 0.92 : 0.86;
    final navScale = screenWidth < 700 ? 0.96 : 1.02;

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
                  Container(
                    height: 54 * scale,
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: const Color(0xFF1E5CE4),
                          size: 18 * scale,
                        ),
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
                          missionState.title,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 11 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        14 * scale,
                        14 * scale,
                        14 * scale,
                        8 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 84 * scale,
                              height: 84 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F1FF),
                                borderRadius: BorderRadius.circular(42 * scale),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 44 * scale,
                                color: const Color(0xFF0A67B3),
                              ),
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          Text(
                            isCompleted
                                ? 'Mission Completed'
                                : 'Mission In Progress',
                            style: TextStyle(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF20252B),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            isCompleted
                                ? 'All clinical protocols successfully finalized.'
                                : 'Ambulance mission workflow is currently active.',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: const Color(0xFF616C7B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          _PatientStatusCard(
                            patientName: patientName,
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          _DestinationRow(
                            destinationName: destinationName,
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  title: 'TOTAL TIME',
                                  value:
                                      '${totalDurationMin.floor()}m\n${((totalDurationMin * 60) % 60).round()}s',
                                  subtitle: 'Optimized route',
                                  icon: Icons.schedule,
                                  scale: scale,
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Expanded(
                                child: _InfoCard(
                                  title: 'DISTANCE',
                                  value:
                                      '${totalDistanceKm.toStringAsFixed(1)} km',
                                  subtitle: nextHint ?? 'Direct corridor',
                                  icon: Icons.alt_route,
                                  scale: scale,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * scale),
                          Container(
                            height: 88 * scale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12 * scale),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF072B52), Color(0xFF1A89D1)],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: EdgeInsets.all(10 * scale),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * scale,
                                  vertical: 6 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.route,
                                      size: 14 * scale,
                                      color: const Color(0xFF0E3E7C),
                                    ),
                                    SizedBox(width: 4 * scale),
                                    Text(
                                      'ROUTE LOGS ARCHIVED',
                                      style: TextStyle(
                                        fontSize: 10 * scale,
                                        color: const Color(0xFF0E3E7C),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          SizedBox(
                            width: double.infinity,
                            height: 48 * scale,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1874D9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12 * scale,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'READY FOR NEXT MISSION',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13 * scale,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Icon(Icons.arrow_forward, size: 18 * scale),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 66 * navScale,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24 * navScale,
                      vertical: 8 * navScale,
                    ),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BottomIcon(
                          label: 'MISSIONS',
                          icon: Icons.assignment_outlined,
                          active: true,
                          scale: navScale,
                          onTap: () {},
                        ),
                        _BottomIcon(
                          label: 'MAP',
                          icon: Icons.map,
                          active: false,
                          scale: navScale,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        _BottomIcon(
                          label: 'PROFILE',
                          icon: Icons.person_outline,
                          active: false,
                          scale: navScale,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientStatusCard extends StatelessWidget {
  const _PatientStatusCard({required this.patientName, required this.scale});

  final String patientName;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        children: [
          Container(
            width: 50 * scale,
            height: 50 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Icon(
              Icons.medical_services,
              color: const Color(0xFF1D6EDA),
              size: 24 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED PATIENT',
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 25 * scale,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF222831),
                  ),
                ),
                Text(
                  'Critical Cardiac Care Unit',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: const Color(0xFF697587),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.destinationName, required this.scale});

  final String destinationName;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        children: [
          Container(
            width: 32 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(
              Icons.local_hospital,
              size: 16 * scale,
              color: const Color(0xFF1D6EDA),
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  destinationName,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: const Color(0xFF262B33),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: const Color(0xFF8B97AA),
            size: 20 * scale,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.scale,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(11 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10 * scale,
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            value,
            style: TextStyle(
              fontSize: 28 * scale,
              height: 1,
              color: const Color(0xFF222831),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Icon(icon, size: 13 * scale, color: const Color(0xFF1D6EDA)),
              SizedBox(width: 5 * scale),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: const Color(0xFF1D6EDA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.label,
    required this.icon,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12 * scale),
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
                borderRadius: BorderRadius.circular(12 * scale),
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
