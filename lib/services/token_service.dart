import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// Make TokenService a proper singleton
class TokenService {
  // Singleton instance
  static final TokenService _instance = TokenService._internal();

  // Factory constructor to return the same instance
  factory TokenService() {
    return _instance;
  }

  // Private constructor for singleton
  TokenService._internal();

  // Class members
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

    // Skip notification permissions for web platform (handled differently)
    if (!kIsWeb) {
      await _requestPermissions();

      // Setup token refresh listener (not needed for web)
      initTokenRefreshListener();
    } else {
      print(
          '[TokenService] Web platform detected, using web-specific initialization');
    }

    // Setup auth state change listener - only save token on actual login
    _auth.authStateChanges().listen((User? user) {
      print('[TokenService] Auth state changed, user: ${user?.uid}');
      if (user != null) {
        // Delay token save to avoid race conditions
        Future.delayed(Duration(milliseconds: 500), () {
          saveToken('auth_state_change');
        });
      }
    });

    // If user is already logged in, save the token once
    if (_auth.currentUser != null) {
      // Small delay to let the app fully initialize
      Future.delayed(Duration(milliseconds: 1000), () {
        saveToken('initialization');
      });
    }
  }

  // Request permissions for all platforms
  Future<bool> _requestPermissions() async {
    try {
      print('[TokenService] Requesting notification permission');

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

  // Get FCM token with platform-specific handling
  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        // For web, check if service worker is registered before trying to get token
        try {
          // Get service worker registration status
          if (!(await _isServiceWorkerAvailable())) {
            print(
                '[TokenService] No active service worker found for web platform');
            // Use a dummy token for web when service worker is not available
            return 'web-${_auth.currentUser?.uid}-${DateTime.now().millisecondsSinceEpoch}';
          }
        } catch (e) {
          print('[TokenService] Error checking service worker: $e');
          // Return dummy token on error
          return 'web-${_auth.currentUser?.uid}-${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      // Get the actual token
      return await _messaging.getToken();
    } catch (e) {
      print('[TokenService] Error getting FCM token: $e');

      // For web platform, return a dummy token on error
      if (kIsWeb) {
        return 'web-${_auth.currentUser?.uid}-${DateTime.now().millisecondsSinceEpoch}';
      }
      return null;
    }
  }

  // Check if service worker is available (web only)
  Future<bool> _isServiceWorkerAvailable() async {
    if (!kIsWeb) return true;

    // This function is only meaningful for web
    try {
      // Using navigator object directly would require js interop
      // For simplicity, just check if getToken() completes without error
      final token = await _messaging.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('[TokenService] Service worker check failed: $e');
      return false;
    }
  }

  // Save or update token with debouncing to prevent multiple calls
  Future<void> saveToken([String source = 'unknown']) async {
    // Don't allow concurrent save operations
    if (_isSaving) {
      print(
          '[TokenService] Token save already in progress, skipping (source: $source)');
      return;
    }

    _isSaving = true;
    print('[TokenService] Starting token save (source: $source)');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print(
            '[TokenService] Cannot save token: No user logged in (source: $source)');
        _isSaving = false;
        return;
      }

      // Skip permission check for web platform
      if (!kIsWeb) {
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

          if (newSettings.authorizationStatus !=
                  AuthorizationStatus.authorized &&
              newSettings.authorizationStatus !=
                  AuthorizationStatus.provisional) {
            print(
                '[TokenService] User declined notification permissions (source: $source)');
            _isSaving = false;
            return;
          }
        }
      }

      // Get the FCM token with platform-specific handling
      print('[TokenService] Getting FCM token (source: $source)');
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        print('[TokenService] Failed to get valid FCM token (source: $source)');
        _isSaving = false;
        return;
      }

      // Prevent duplicate saves of the same token within a short time period
      final now = DateTime.now();
      if (token == _lastSavedToken &&
          _lastSaveTime != null &&
          now.difference(_lastSaveTime!).inMinutes < 5) {
        print(
            '[TokenService] Token already saved recently, skipping (source: $source)');
        _isSaving = false;
        return;
      }

      print(
          "[TokenService] Got token: ${token.substring(0, min(token.length, 10))}... (source: $source)");
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
          'platform': kIsWeb ? 'web' : 'mobile'
        }),
      );

      print(
          "[TokenService] Response status: ${response.statusCode} (source: $source)");

      if (response.statusCode == 200) {
        print('[TokenService] Token saved successfully (source: $source)');
        // Update last saved token info
        _lastSavedToken = token;
        _lastSaveTime = now;
      } else {
        print("[TokenService] Response body: ${response.body}");
        throw Exception('Failed to save token: ${response.body}');
      }
    } catch (e) {
      print('[TokenService] Error saving token: $e (source: $source)');
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

      String? token;

      // For web platform, handle differently
      if (kIsWeb) {
        // Use the cached token if available
        token = _lastSavedToken;

        // If no cached token, try to get a new one
        if (token == null) {
          token = await _getToken();
        }
      } else {
        // For mobile, get the token normally
        token = await _messaging.getToken();
      }

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
    // Skip for web platform
    if (kIsWeb) {
      print('[TokenService] Skipping token refresh listener for web platform');
      return;
    }

    print('[TokenService] Setting up token refresh listener');
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      print('[TokenService] FCM token refreshed');

      // Wait a moment before saving the refreshed token
      await Future.delayed(Duration(milliseconds: 500));

      // Clear last token info to force a save for the new token
      _lastSavedToken = null;
      _lastSaveTime = null;

      // Save the new token
      saveToken('token_refresh');
    });
  }

  // Helper to safely get substring length
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
