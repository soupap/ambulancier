import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static const String _apiBaseOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _keycloakDiscoveryOverride = String.fromEnvironment(
    'KEYCLOAK_DISCOVERY_URL',
    defaultValue: '',
  );
  static const String _websocketOverride = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );

  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'emscommandcenter',
  );

  static const String redirectUri = String.fromEnvironment(
    'KEYCLOAK_REDIRECT_URI',
    defaultValue: 'com.example.incidentreporter://oauthredirect',
  );

  static const String osrmBaseUrl = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  static bool get allowInsecureConnections => !kReleaseMode;

  static String get apiBaseUrl {
    if (_apiBaseOverride.isNotEmpty) {
      return _apiBaseOverride;
    }
    return _isAndroid ? 'http://10.0.2.2:8081' : 'http://localhost:8081';
  }

  static String get keycloakDiscoveryUrl {
    if (_keycloakDiscoveryOverride.isNotEmpty) {
      return _keycloakDiscoveryOverride;
    }
    final host = _isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8080/realms/ems-command-center/.well-known/openid-configuration';
  }

  static String get websocketUrl {
    if (_websocketOverride.isNotEmpty) {
      return _websocketOverride;
    }
    final host = _isAndroid ? '10.0.2.2' : 'localhost';
    return 'ws://$host:8081/ws-native';
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
