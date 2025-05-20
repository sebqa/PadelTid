import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class TokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiUrl =
      'https://kgzbg5117d.execute-api.eu-north-1.amazonaws.com/default/manageTokens'; // Create new Lambda endpoint

  // Add variables to track token save operations
  String? _lastSavedToken;
  DateTime? _lastSaveTime;
  bool _isInitialized = false;
  bool _isSaving = false;

  // Initialize token service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[TokenService] Already initialized, skipping');
      return;
    }

    print('[TokenService] Initializing');
    _isInitialized = true;

    // Request notification permissions early for all platforms
    await _requestPermissions();

    // Setup auth state change listener - only save token on actual login
    _auth.authStateChanges().listen((User? user) {
      print('[TokenService] Auth state changed, user: ${user?.uid}');
      if (user != null) {
        // Delay token save to avoid race conditions
        Future.delayed(Duration(milliseconds: 500), () {
          saveToken();
        });
      }
    });

    // Initialize token refresh listener
    initTokenRefreshListener();

    // If user is already logged in, save the token once
    if (_auth.currentUser != null) {
      // Small delay to let the app fully initialize
      Future.delayed(Duration(milliseconds: 1000), () {
        saveToken();
      });
    }
  }

  // Request permissions for all platforms
  Future<bool> _requestPermissions() async {
    try {
      print('[TokenService] Requesting notification permissions');

      // For iOS, we need to request permissions before getting the token
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print(
          '[TokenService] Permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('[TokenService] Error requesting permissions: $e');
      return false;
    }
  }

  // Save or update token with debouncing to prevent multiple calls
  Future<void> saveToken() async {
    // Don't allow concurrent save operations
    if (_isSaving) {
      print('[TokenService] Token save already in progress, skipping');
      return;
    }

    _isSaving = true;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[TokenService] Cannot save token: No user logged in');
        _isSaving = false;
        return;
      }

      // Check notification settings status
      print('[TokenService] Checking notification permission');
      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print(
            '[TokenService] Notifications not authorized, requesting permission');
        final newSettings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (newSettings.authorizationStatus != AuthorizationStatus.authorized &&
            newSettings.authorizationStatus !=
                AuthorizationStatus.provisional) {
          print('[TokenService] User declined notification permissions');
          _isSaving = false;
          return;
        }
      }

      // Get the FCM token
      print('[TokenService] Getting FCM token');
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        print('[TokenService] Failed to get valid FCM token');
        _isSaving = false;
        return;
      }

      // Prevent duplicate saves of the same token within a short time period
      final now = DateTime.now();
      if (token == _lastSavedToken &&
          _lastSaveTime != null &&
          now.difference(_lastSaveTime!).inMinutes < 5) {
        print('[TokenService] Token already saved recently, skipping');
        _isSaving = false;
        return;
      }

      print(
          "[TokenService] Got token: ${token.substring(0, min(token.length, 10))}...");
      print("[TokenService] Making POST request to save token");

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

      if (response.statusCode == 200) {
        print('[TokenService] Token saved successfully');
        // Update last saved token info
        _lastSavedToken = token;
        _lastSaveTime = now;
      } else {
        print("[TokenService] Response body: ${response.body}");
        throw Exception('Failed to save token: ${response.body}');
      }
    } catch (e) {
      print('[TokenService] Error saving token: $e');
      print('[TokenService] Stack trace: ${StackTrace.current}');
    } finally {
      _isSaving = false;
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
      if (token == null || token.isEmpty) return;

      print(
          "[TokenService] Removing token: ${token.substring(0, min(token.length, 10))}...");

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json
            .encode({'userId': user.uid, 'token': token, 'action': 'remove'}),
      );

      print("[TokenService] Remove token response: ${response.statusCode}");

      if (response.statusCode == 200) {
        print('[TokenService] Token removed successfully');
        _lastSavedToken = null;
        _lastSaveTime = null;
      } else {
        throw Exception('Failed to remove token: ${response.body}');
      }
    } catch (e) {
      print('[TokenService] Error removing token: $e');
    }
  }

  void initTokenRefreshListener() {
    print('[TokenService] Setting up token refresh listener');
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      print('[TokenService] FCM token refreshed');

      // Wait a moment before saving the refreshed token
      await Future.delayed(Duration(milliseconds: 500));

      // Clear last token info to force a save for the new token
      _lastSavedToken = null;
      _lastSaveTime = null;

      // Save the new token
      saveToken();
    });
  }

  // Helper to safely get substring length
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
