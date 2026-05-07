import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/services/driver_app_controller.dart';

class LoginScreen extends GetView<DriverAppController> {
  const LoginScreen({super.key});

  Future<void> _login() async {
    final success = await controller.login();
    if (!success) {
      Get.snackbar(
        'Authentication failed',
        'Keycloak authentication failed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E1728), Color(0xFF1E3556), Color(0xFFDA3E52)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 14,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE7EB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: Color(0xFFDA3E52),
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ambulancier',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Secure driver access with Keycloak. After login, the app loads your saved dispatch assignment and live route automatically.',
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.isLoggingIn ? null : _login,
                              icon: controller.isLoggingIn
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.lock_open_rounded),
                              label: Text(
                                controller.isLoggingIn
                                    ? 'Authorizing...'
                                    : 'Sign In with Keycloak',
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Use a DRIVER account that has an ambulance assignment in Keycloak and the EMS backend.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
