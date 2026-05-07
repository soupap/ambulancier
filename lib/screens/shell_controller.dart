import 'package:get/get.dart';

class ShellController extends GetxController {
  final selectedTabIndex = 0.obs;
  final missionPanelExpanded = true.obs;

  void selectTab(int index) {
    selectedTabIndex.value = index;
  }

  void toggleMissionPanel() {
    missionPanelExpanded.toggle();
  }

  void reset() {
    selectedTabIndex.value = 0;
    missionPanelExpanded.value = true;
  }
}
