import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _expiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // Save login data
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required int expiresIn,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Calculate expiry timestamp
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_tokenTypeKey, tokenType);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_expiryKey, expiryTime.toIso8601String());

    if (userData != null) {
      await prefs.setString(_userDataKey, jsonEncode(userData));
    }
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get token type
  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey) ?? 'Bearer';
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get full authorization header
  static Future<String?> getAuthHeader() async {
    final token = await getAccessToken();
    final tokenType = await getTokenType();

    if (token != null) {
      return '$tokenType $token';
    }
    return null;
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_expiryKey);

    if (expiryString == null) return true;

    final expiryTime = DateTime.parse(expiryString);
    // Consider token expired 5 minutes before actual expiry
    final bufferTime = DateTime.now().add(Duration(minutes: 5));

    return bufferTime.isAfter(expiryTime);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;

    final isExpired = await isTokenExpired();
    return !isExpired;
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Logout - clear all auth data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_expiryKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
  }

  // Clear all data (for debugging)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}