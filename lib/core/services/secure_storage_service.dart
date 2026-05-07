import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }

    if (idToken != null) {
      await prefs.setString(_idTokenKey, idToken);
    } else {
      await prefs.remove(_idTokenKey);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_idTokenKey);
  }
}
