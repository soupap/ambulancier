import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/models/assignment_stage.dart';
import 'package:incident_reporter/services/driver_app_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DriverAppController.instance;

    return Obx(() {
      final profile = controller.profile;
      final vehicle = controller.vehicle;

      if (profile == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Driver profile')),
          body: const Center(child: Text('Profile not loaded yet.')),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver profile'),
          actions: [
            IconButton(
              onPressed: controller.refreshAll,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFFFE6EA),
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDA3E52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.sessionToken ?? 'ID: --',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy',
                                onPressed: controller.sessionToken == null
                                    ? null
                                    : () {
                                        Clipboard.setData(
                                          ClipboardData(
                                              text: controller.sessionToken!),
                                        );
                                        Get.snackbar(
                                          'Copied',
                                          'Session token copied to clipboard',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      },
                              ),
                            ],
                          ),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(profile.email),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusPill(label: profile.role),
                              _StatusPill(label: profile.status),
                              if (profile.ambulanceId != null)
                                _StatusPill(label: profile.ambulanceId!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Assignment summary',
              children: [
                _InfoTile(
                  label: 'Current stage',
                  value: controller.missionStage.label,
                ),
                _InfoTile(
                  label: 'Hospital',
                  value: controller.hospital?.name ?? 'Not assigned',
                ),
                _InfoTile(
                  label: 'Vehicle',
                  value: vehicle?.name ?? 'Unknown ambulance',
                ),
                _InfoTile(
                  label: 'Vehicle status',
                  value: vehicle?.status ?? '--',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Driver details',
              children: [
                _InfoTile(label: 'Phone', value: profile.phone ?? '--'),
                _InfoTile(label: 'License', value: profile.license ?? '--'),
                _InfoTile(label: 'Station', value: profile.station ?? '--'),
                _InfoTile(
                  label: 'Experience',
                  value: profile.experience == null
                      ? '--'
                      : '${profile.experience} years',
                ),
                _InfoTile(
                  label: 'Rating',
                  value: profile.rating == null
                      ? '--'
                      : profile.rating!.toStringAsFixed(1),
                ),
                _InfoTile(
                  label: 'Total missions',
                  value: profile.totalMissions?.toString() ?? '--',
                ),
                _InfoTile(
                  label: 'This month',
                  value: profile.missionsThisMonth?.toString() ?? '--',
                ),
                _InfoTile(
                  label: 'Certifications',
                  value: profile.certifications.isEmpty
                      ? '--'
                      : profile.certifications.join(', '),
                  multiline: true,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        value,
        maxLines: multiline ? 4 : 1,
        overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDA3E52),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
