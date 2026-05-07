import 'package:get/get.dart';
import 'package:incident_reporter/app/routes/app_routes.dart';
import 'package:incident_reporter/screens/driver_app_shell.dart';
import 'package:incident_reporter/screens/login_screen.dart';
import 'package:incident_reporter/screens/splash_screen.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.shell,
      page: () => const DriverAppShell(),
    ),
  ];
}
