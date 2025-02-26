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

  Future<List<Document>> fetchDocuments(
      double windSpeed,
      double precipitationProbability,
      double temperature,
      bool showUnavailableSlots,
      bool fetchRecommended,
      List<String> selectedLocations) async {
    // Create a cache key based on parameters
    final cacheKey =
        '${windSpeed}_${precipitationProbability}_${temperature}_${showUnavailableSlots}_${fetchRecommended}_${selectedLocations.join(',')}';

    // Check if cache is valid
    final now = DateTime.now();
    if (_cachedResults.containsKey(cacheKey) &&
        now.difference(_lastCacheTime) < cacheDuration) {
      print('Using cached data for $cacheKey');
      return _cachedResults[cacheKey];
    }

    List<dynamic> subscribedDocs = [];

    if (!fetchRecommended) {
      subscribedDocs = await getSubscribedDocs();
    }

    final user = FirebaseAuth.instance.currentUser;
    final queryParams = {
      'wind_speed_threshold': windSpeed.toString(),
      'precipitation_probability_threshold':
          precipitationProbability.toString(),
      'temperature_threshold': temperature.toString(),
      'showUnavailableSlots': showUnavailableSlots.toString(),
      'locations': selectedLocations.join(','),
      if (user != null) 'user_id': user.uid,
    };

    try {
      final url = Uri.parse(
              'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid')
          .replace(queryParameters: queryParams);

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final results = jsonList
            .map((json) => Document.fromJson(json, subscribedDocs,
                selectedLocations: selectedLocations))
            .where((doc) =>
                selectedLocations.isEmpty ||
                doc.clubs.keys.any((club) => selectedLocations.contains(club)))
            .toList();

        // Cache the results
        _cachedResults[cacheKey] = results;
        _lastCacheTime = now;

        // Also store the most common query in local storage for faster initial load
        if (!fetchRecommended && selectedLocations.isNotEmpty) {
          _saveToLocalCache(results);
        }

        return results;
      } else {
        // If request fails, try to use cached data even if expired
        if (_cachedResults.containsKey(cacheKey)) {
          return _cachedResults[cacheKey];
        }
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      // On error, try to use cached data or local storage
      if (_cachedResults.containsKey(cacheKey)) {
        return _cachedResults[cacheKey];
      }

      // Try to load from local storage as fallback
      final localData = await _loadFromLocalCache();
      if (localData.isNotEmpty) {
        return localData;
      }

      throw Exception('Failed to load documents: $e');
    }
  }

  // Save frequently used data to local storage
  Future<void> _saveToLocalCache(List<Document> documents) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = documents
          .map((doc) => {
                'date': doc.date,
                'time': doc.time,
                // Serialize only essential data
              })
          .toList();
      await prefs.setString('cached_documents', json.encode(jsonData));
    } catch (e) {
      print('Error saving to local cache: $e');
    }
  }

  // Load data from local storage
  Future<List<Document>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_documents');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        // Convert back to Document objects
        return jsonList.map((json) => Document.fromJson(json, [])).toList();
      }
    } catch (e) {
      print('Error loading from local cache: $e');
    }
    return [];
  }

  Future<List<dynamic>> getSubscribedDocs() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      Uri url = Uri.parse(
          'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getSubscribed?userId=${userId}');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> subscriptions = json.decode(response.body);

        // Return full subscription objects instead of just IDs
        return subscriptions.where((sub) {
          final preferences = sub['preferences'] as Map<String, dynamic>;
          return preferences.values.any((value) => value == true);
        }).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } else {
      return [];
    }
  }
}
