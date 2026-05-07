import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/screens/map_screen.dart';
import 'package:incident_reporter/screens/notifications_screen.dart';
import 'package:incident_reporter/screens/profile_screen.dart';
import 'package:incident_reporter/screens/shell_controller.dart';

class DriverAppShell extends GetView<ShellController> {
  const DriverAppShell({super.key});

  static const _pages = <Widget>[
    DriverMapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedTabIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedTabIndex.value,
          onDestinationSelected: controller.selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital),
              label: 'Dispatch',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
