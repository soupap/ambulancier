import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/app/bindings/app_binding.dart';
import 'package:incident_reporter/app/routes/app_pages.dart';
import 'package:incident_reporter/app/routes/app_routes.dart';

/*
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081 --dart-define=KEYCLOAK_DISCOVERY_URL=http://10.0.2.2:8080/realms/ems-command-center/.well-known/openid-configuration
*/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AmbulancierApp());
}

class AmbulancierApp extends StatelessWidget {
  const AmbulancierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambulancier',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDA3E52),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
