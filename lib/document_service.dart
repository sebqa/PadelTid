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
      {bool notifyOnMatchingCourts = false}) async {
    final user = FirebaseAuth.instance.currentUser;

    // Create cache keys for both types of requests
    final filterCacheKey =
        '${windSpeed}_${precipitationProbability}_${temperature}_${showUnavailableSlots}_false_${notifyOnMatchingCourts}_${selectedLocations.join(',')}';
    final recommendedCacheKey =
        '${windSpeed}_${precipitationProbability}_${temperature}_${showUnavailableSlots}_true_${notifyOnMatchingCourts}_${selectedLocations.join(',')}';

    // Check if cache is valid
    final now = DateTime.now();
    final isCacheValid = now.difference(_lastCacheTime) < cacheDuration;

    // Prepare result containers
    List<Document> filteredDocuments = [];
    List<Document> recommendedDocuments = [];

    // Try to load from cache first
    bool needFetchFiltered = true;
    bool needFetchRecommended = true;

    if (isCacheValid) {
      if (_cachedResults.containsKey(filterCacheKey)) {
        print('Using cached data for filtered documents');
        filteredDocuments = _cachedResults[filterCacheKey];
        needFetchFiltered = false;
      }

      if (_cachedResults.containsKey(recommendedCacheKey)) {
        print('Using cached data for recommended documents');
        recommendedDocuments = _cachedResults[recommendedCacheKey];
        needFetchRecommended = false;
      }
    }

    // Fetch data if needed
    try {
      // If both are available in cache, return early
      if (!needFetchFiltered && !needFetchRecommended) {
        return {
          'filtered': filteredDocuments,
          'recommended': recommendedDocuments,
        };
      }

      // Get subscriptions if user is logged in
      List<dynamic> subscribedDocs = [];
      if (user != null) {
        subscribedDocs = await getSubscribedDocs();
      }

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

      // Make a single request for both types of documents
      final queryParams = {
        ...baseQueryParams,
        'fetch_both': 'true', // New parameter to indicate we want both types
      };

      final url = Uri.parse(
              'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid')
          .replace(queryParameters: queryParams);

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Process filtered documents
        if (needFetchFiltered && responseData.containsKey('filtered')) {
          final List<dynamic> filteredJson = responseData['filtered'];
          filteredDocuments = filteredJson
              .map((json) => Document.fromJson(json, subscribedDocs,
                  selectedLocations: selectedLocations))
              .where((doc) =>
                  selectedLocations.isEmpty ||
                  doc.clubs.keys
                      .any((club) => selectedLocations.contains(club)))
              .toList();

          // Cache the results
          _cachedResults[filterCacheKey] = filteredDocuments;

          // Store in local cache for faster initial load
          if (selectedLocations.isNotEmpty) {
            _saveToLocalCache(filteredDocuments);
          }
        }

        // Process recommended documents
        if (needFetchRecommended && responseData.containsKey('recommended')) {
          final List<dynamic> recommendedJson = responseData['recommended'];
          recommendedDocuments = recommendedJson
              .map((json) => Document.fromJson(json, subscribedDocs,
                  selectedLocations: selectedLocations))
              .where((doc) =>
                  selectedLocations.isEmpty ||
                  doc.clubs.keys
                      .any((club) => selectedLocations.contains(club)))
              .toList();

          // Cache the results
          _cachedResults[recommendedCacheKey] = recommendedDocuments;
        }

        _lastCacheTime = now;
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      // On error, try to use cached data or local storage
      if (filteredDocuments.isEmpty &&
          _cachedResults.containsKey(filterCacheKey)) {
        filteredDocuments = _cachedResults[filterCacheKey];
      }

      if (recommendedDocuments.isEmpty &&
          _cachedResults.containsKey(recommendedCacheKey)) {
        recommendedDocuments = _cachedResults[recommendedCacheKey];
      }

      // Try to load from local storage as fallback for filtered docs
      if (filteredDocuments.isEmpty) {
        filteredDocuments = await _loadFromLocalCache();
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

  // This method is now deprecated as we get subscriptions directly from the API
  // Keeping it for backwards compatibility but it should be removed eventually
  Future<List<dynamic>> getSubscribedDocs() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        Uri url = Uri.parse(
            'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getSubscribed?userId=${userId}');

        final response = await http.get(url);
        if (response.statusCode == 200) {
          List<dynamic> subscriptions = json.decode(response.body);

          return subscriptions.where((sub) {
            if (sub is Map<String, dynamic> && sub.containsKey('preferences')) {
              final preferences = sub['preferences'] as Map<String, dynamic>;
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
