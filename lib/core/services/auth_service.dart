import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/services/secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final SecureStorageService _storage = SecureStorageService.instance;
  final RxBool isAuthenticated = false.obs;
  final RxBool isAuthenticating = false.obs;

  static const List<String> _scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  Future<void> init() async {
    final token = await getValidToken();
    isAuthenticated.value = token != null;
  }

  Future<bool> login() async {
    isAuthenticating.value = true;

    if (AppConfig.demoMode) {
      await _storage.saveTokens(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
        idToken: 'demo-id-token',
      );
      isAuthenticated.value = true;
      isAuthenticating.value = false;
      return true;
    }

    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.keycloakClientId,
          AppConfig.redirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
          scopes: _scopes,
          allowInsecureConnections: AppConfig.allowInsecureConnections,
          promptValues: const ['login'],
        ),
      );

      if (result.accessToken == null) {
        return false;
      }

      await _storage.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
      isAuthenticated.value = true;
      return true;
    } catch (error) {
      debugPrint('Keycloak login failed: $error');
      return false;
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<String?> getValidToken() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      return null;
    }

    if (AppConfig.demoMode || !JwtDecoder.isExpired(accessToken)) {
      return accessToken;
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await logout();
      return null;
    }

    try {
      final TokenResponse response = await _appAuth.token(
        TokenRequest(
          AppConfig.keycloakClientId,
          AppConfig.redirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
          refreshToken: refreshToken,
          scopes: _scopes,
          allowInsecureConnections: AppConfig.allowInsecureConnections,
        ),
      );

      if (response.accessToken == null) {
        await logout();
        return null;
      }

      await _storage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken ?? refreshToken,
        idToken: response.idToken,
      );
      isAuthenticated.value = true;
      return response.accessToken;
    } catch (error) {
      debugPrint('Token refresh failed: $error');
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    isAuthenticated.value = false;
  }
}
