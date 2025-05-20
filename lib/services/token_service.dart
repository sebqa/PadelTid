import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class TokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiUrl =
      'https://kgzbg5117d.execute-api.eu-north-1.amazonaws.com/default/manageTokens'; // Create new Lambda endpoint

  // Initialize token service
  Future<void> initialize() async {
    print('[TokenService] Initializing');

    // Request notification permissions early for all platforms
    await _requestPermissions();

    // Setup auth state change listener
    _auth.authStateChanges().listen((User? user) {
      print('[TokenService] Auth state changed, user: ${user?.uid}');
      if (user != null) {
        saveToken();
      }
    });

    // Initialize token refresh listener
    initTokenRefreshListener();
  }

  // Request permissions for all platforms
  Future<bool> _requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
          '[TokenService] Permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('[TokenService] Error requesting permissions: $e');
      return false;
    }
  }

  // Save or update token
  Future<void> saveToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[TokenService] Cannot save token: No user logged in');
        return;
      }

      // Check notification settings for all platforms
      print('[TokenService] Checking notification permission');
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('[TokenService] Notifications not authorized');
        final newSettings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (newSettings.authorizationStatus != AuthorizationStatus.authorized) {
          print('[TokenService] User declined notification permissions');
          return;
        }
      }

      print('[TokenService] Getting FCM token');
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        print('[TokenService] Failed to get valid FCM token');
        return;
      }

      print(
          "[TokenService] Got token: ${token.substring(0, 10)}..."); // Partial token for privacy
      print("[TokenService] Making POST request to save token");
      print("[TokenService] URL: $_apiUrl");

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': user.uid,
          'token': token,
          'action': 'save',
        }),
      );

      print("[TokenService] Response status: ${response.statusCode}");
      print("[TokenService] Response body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to save token: ${response.body}');
      } else {
        print('[TokenService] Token saved successfully');
      }
    } catch (e) {
      print('[TokenService] Error saving token: $e');
      print('[TokenService] Stack trace: ${StackTrace.current}');
    }
  }

  // Get all valid tokens for a user
  Future<List<String>> getUserTokens(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['tokens']);
      }
      return [];
    } catch (e) {
      print('[TokenService] Error getting user tokens: $e');
      return [];
    }
  }

  // Remove token
  Future<void> removeToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json
            .encode({'userId': user.uid, 'token': token, 'action': 'remove'}),
      );

      print(
          "[TokenService] Remove token response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to remove token: ${response.body}');
      }
    } catch (e) {
      print('[TokenService] Error removing token: $e');
      print('[TokenService] Stack trace: ${StackTrace.current}');
    }
  }

  void initTokenRefreshListener() {
    print('[TokenService] Setting up token refresh listener');
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      print('[TokenService] FCM token refreshed');
      final user = _auth.currentUser;
      if (user != null) {
        try {
          // Check notification permission for all platforms
          final settings = await _messaging.getNotificationSettings();
          if (settings.authorizationStatus != AuthorizationStatus.authorized) {
            print(
                '[TokenService] No notification permissions for token refresh');
            return;
          }

          print("[TokenService] Saving refreshed token");
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'userId': user.uid,
              'token': token,
              'action': 'save',
            }),
          );

          print(
              "[TokenService] Token refresh response: ${response.statusCode}");

          if (response.statusCode != 200) {
            throw Exception('Failed to save refreshed token: ${response.body}');
          }
        } catch (e) {
          print('[TokenService] Error saving refreshed token: $e');
          print('[TokenService] Stack trace: ${StackTrace.current}');
        }
      }
    });
  }
}
