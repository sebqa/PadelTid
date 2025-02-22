import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

class TokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiUrl = 'https://kgzbg5117d.execute-api.eu-north-1.amazonaws.com/default/manageTokens'; // Create new Lambda endpoint

  // Save or update token
  Future<void> saveToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      print("Making POST request to save token"); // Debug log
      print("URL: $_apiUrl"); // Debug log

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': user.uid,
          'token': token,
          'platform': defaultTargetPlatform.toString(),
          'action': 'save'
        }),
      );

      print("Response status: ${response.statusCode}"); // Debug log
      print("Response body: ${response.body}"); // Debug log
      print("Response headers: ${response.headers}"); // Debug log

      if (response.statusCode != 200) {
        throw Exception('Failed to save token: ${response.body}');
      }
    } catch (e) {
      print('Error saving token: $e');
      print('Stack trace: ${StackTrace.current}');
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
      print('Error getting user tokens: $e');
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
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        body: json.encode({
          'userId': user.uid,
          'token': token,
          'action': 'remove'
        }),
      );

      print("Remove token response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to remove token: ${response.body}');
      }
    } catch (e) {
      print('Error removing token: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  void initTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            },
            body: json.encode({
              'userId': user.uid,
              'token': token,
              'platform': defaultTargetPlatform.toString(),
              'action': 'save'
            }),
          );

          print("Token refresh response: ${response.statusCode} - ${response.body}");

          if (response.statusCode != 200) {
            throw Exception('Failed to save refreshed token: ${response.body}');
          }
        } catch (e) {
          print('Error saving refreshed token: $e');
          print('Stack trace: ${StackTrace.current}');
        }
      }
    });
  }
} 