import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentService {
  // Add cache variables
  static Map<String, dynamic> _cachedResults = {};
  static DateTime _lastCacheTime = DateTime.now();
  static const cacheDuration = Duration(minutes: 5);

  Future<Document> getDocumentById(String documentId) async {
    try {
      // Use the correct endpoint for fetching document by ID
      final response = await http.get(
        Uri.parse(
            'https://4ui8jbkcgc.execute-api.eu-north-1.amazonaws.com/default/getDocumentById?documentId=$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Document.fromJson(data, []);
      } else {
        throw Exception('Failed to load document: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching document: $e');
      throw Exception('Failed to load document: $e');
    }
  }

  // Combined function to fetch both recommended and filtered documents in one call
  Future<Map<String, List<Document>>> fetchAllDocuments(
      double windSpeed,
      double precipitationProbability,
      double temperature,
      bool showUnavailableSlots,
      List<String> selectedLocations,
      {bool notifyOnMatchingCourts = false,
      double? notificationWindThreshold,
      double? notificationPrecipitationThreshold,
      double? notificationTemperatureThreshold}) async {
    final user = FirebaseAuth.instance.currentUser;

    // Logging filter parameters
    print('[Filter] windSpeed: '
        '[32m$windSpeed\u001b[0m, precipitationProbability: '
        '[32m$precipitationProbability\u001b[0m, temperature: '
        '[32m$temperature\u001b[0m, showUnavailableSlots: '
        '[32m$showUnavailableSlots\u001b[0m, selectedLocations: '
        '[32m$selectedLocations\u001b[0m, notifyOnMatchingCourts: '
        '[32m$notifyOnMatchingCourts\u001b[0m');

    // Log notification thresholds if enabled
    if (notifyOnMatchingCourts) {
      print('[Filter] Notification thresholds - wind: '
          '[32m$notificationWindThreshold\u001b[0m, precipitation: '
          '[32m$notificationPrecipitationThreshold\u001b[0m, temperature: '
          '[32m$notificationTemperatureThreshold\u001b[0m');
    }

    // Prepare result containers
    List<Document> filteredDocuments = [];
    List<Document> recommendedDocuments = [];

    try {
      // Base query parameters
      final baseQueryParams = {
        'wind_speed_threshold': windSpeed.toString(),
        'precipitation_probability_threshold':
            precipitationProbability.toString(),
        'temperature_threshold': temperature.toString(),
        'showUnavailableSlots': showUnavailableSlots.toString(),
        'locations': selectedLocations.join(','),
        if (user != null) 'user_id': user.uid,
        if (user != null)
          'notify_on_matching_courts': notifyOnMatchingCourts.toString(),
      };

      // Add notification-specific thresholds if notifications are enabled
      if (notifyOnMatchingCourts && user != null) {
        if (notificationWindThreshold != null) {
          baseQueryParams['notification_wind_threshold'] =
              notificationWindThreshold.toString();
        }
        if (notificationPrecipitationThreshold != null) {
          baseQueryParams['notification_precipitation_threshold'] =
              notificationPrecipitationThreshold.toString();
        }
        if (notificationTemperatureThreshold != null) {
          baseQueryParams['notification_temperature_threshold'] =
              notificationTemperatureThreshold.toString();
        }
      }

      // Make a single request for both types of documents
      final queryParams = {
        ...baseQueryParams,
        'fetch_both': 'true', // New parameter to indicate we want both types
      };

      final url = Uri.parse(
              'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid')
          .replace(queryParameters: queryParams);

      print(
          '[API] Making combined API request to: [34m${url.toString()}\u001b[0m');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Process filtered documents
        if (responseData.containsKey('filtered')) {
          final List<dynamic> filteredJson = responseData['filtered'];
          print(
              '[Filter] Filtering filtered documents by selectedLocations: $selectedLocations');
          filteredDocuments = filteredJson
              .map((json) => Document.fromJson(
                  json, [], // No need for followedDocs parameter
                  selectedLocations: selectedLocations))
              .where((doc) =>
                  selectedLocations.isEmpty ||
                  doc.clubs.keys
                      .any((club) => selectedLocations.contains(club)))
              .toList();
          print(
              '[Filter] Filtered documents count: [32m${filteredDocuments.length}\u001b[0m');

          // Store in local cache for faster initial load
          if (selectedLocations.isNotEmpty) {
            print('[SharedPrefs] Saving filtered documents to local cache');
            await _saveToLocalCache(filteredDocuments);
          }
        }

        // Process recommended documents
        if (responseData.containsKey('recommended')) {
          final List<dynamic> recommendedJson = responseData['recommended'];
          print(
              '[Filter] Filtering recommended documents by selectedLocations: $selectedLocations');
          recommendedDocuments = recommendedJson
              .map((json) => Document.fromJson(
                  json, [], // No need for followedDocs parameter
                  selectedLocations: selectedLocations))
              .where((doc) =>
                  selectedLocations.isEmpty ||
                  doc.clubs.keys
                      .any((club) => selectedLocations.contains(club)))
              .toList();
          print(
              '[Filter] Recommended documents count: [32m${recommendedDocuments.length}\u001b[0m');
        }
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      print('[Error] Exception during fetchAllDocuments: $e');
      // Try to load from local storage as fallback for filtered docs
      if (filteredDocuments.isEmpty) {
        print('[SharedPrefs] Loading filtered documents from local cache');
        filteredDocuments = await _loadFromLocalCache();
        print(
            '[SharedPrefs] Loaded filtered documents from local cache: [32m${filteredDocuments.length}\u001b[0m');
      }
      if (filteredDocuments.isEmpty && recommendedDocuments.isEmpty) {
        throw Exception('Failed to load documents: $e');
      }
    }

    return {
      'filtered': filteredDocuments,
      'recommended': recommendedDocuments,
    };
  }

  // Legacy method for backward compatibility - delegates to the new combined function
  Future<List<Document>> fetchDocuments(
      double windSpeed,
      double precipitationProbability,
      double temperature,
      bool showUnavailableSlots,
      bool fetchRecommended,
      List<String> selectedLocations,
      {bool notifyOnMatchingCourts = false}) async {
    final results = await fetchAllDocuments(windSpeed, precipitationProbability,
        temperature, showUnavailableSlots, selectedLocations,
        notifyOnMatchingCourts: notifyOnMatchingCourts);

    return fetchRecommended ? results['recommended']! : results['filtered']!;
  }

  // Save frequently used data to local storage
  Future<void> _saveToLocalCache(List<Document> documents) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('[SharedPrefs] Got SharedPreferences instance for save');
      final jsonData = documents
          .map((doc) => {
                'date': doc.date,
                'time': doc.time,
                // Serialize only essential data
              })
          .toList();
      await prefs.setString('cached_documents', json.encode(jsonData));
      print('[SharedPrefs] Saved filtered documents to shared preferences');
    } catch (e) {
      print('[SharedPrefs] Error saving to local cache: $e');
    }
  }

  // Load data from local storage
  Future<List<Document>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('[SharedPrefs] Got SharedPreferences instance for load');
      final jsonString = prefs.getString('cached_documents');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        print(
            '[SharedPrefs] Loaded jsonString from shared preferences, count: [32m${jsonList.length}\u001b[0m');
        // Convert back to Document objects
        return jsonList.map((json) => Document.fromJson(json, [])).toList();
      }
    } catch (e) {
      print('[SharedPrefs] Error loading from local cache: $e');
    }
    return [];
  }

  // This method is now deprecated as we get follows directly from the API
  // Keeping it for backwards compatibility but it should be removed eventually
  Future<List<dynamic>> getFollowedDocs() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        Uri url = Uri.parse(
            'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getFollowed?userId=${userId}');

        final response = await http.get(url);
        if (response.statusCode == 200) {
          List<dynamic> follows = json.decode(response.body);

          return follows.where((follow) {
            if (follow is Map<String, dynamic> &&
                follow.containsKey('preferences')) {
              final preferences = follow['preferences'] as Map<String, dynamic>;
              return preferences.values.any((value) => value == true);
            }
            return true; // Include legacy format subscriptions
          }).toList();
        } else {
          print('Failed to fetch subscriptions: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        print('Error fetching subscriptions: $e');
        return [];
      }
    } else {
      return [];
    }
  }
}
