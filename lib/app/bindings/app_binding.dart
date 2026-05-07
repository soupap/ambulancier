import 'package:get/get.dart';
import 'package:incident_reporter/core/services/auth_service.dart';
import 'package:incident_reporter/screens/shell_controller.dart';
import 'package:incident_reporter/services/driver_app_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<ShellController>(ShellController(), permanent: true);
    Get.put<DriverAppController>(DriverAppController(), permanent: true);
  }
}
