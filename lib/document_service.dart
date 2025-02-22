import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:http/http.dart' as http;

class DocumentService {
  Future<List<Document>> fetchDocuments(
      double windSpeed,
      double precipitationProbability,
      double temperature,
      bool showUnavailableSlots,
      bool fetchRecommended,
      List<String> selectedLocations) async {
    List<dynamic> subscribedDocs = [];

    if (!fetchRecommended) {
      subscribedDocs = await getSubscribedDocs();
    }
    
    final user = FirebaseAuth.instance.currentUser;
    final queryParams = {
      'wind_speed_threshold': windSpeed.toString(),
      'precipitation_probability_threshold': precipitationProbability.toString(),
      'temperature_threshold': temperature.toString(),
      'showUnavailableSlots': showUnavailableSlots.toString(),
      'locations': selectedLocations.join(','),
      if (user != null) 'user_id': user.uid,
    };
    
    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid')
        .replace(queryParameters: queryParams);
        
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => Document.fromJson(
              json, 
              subscribedDocs, 
              selectedLocations: selectedLocations
          ))
          .where((doc) => 
            selectedLocations.isEmpty || 
            doc.clubs.keys.any((club) => selectedLocations.contains(club)))
          .toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  Future<List<dynamic>> getSubscribedDocs() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      Uri url = Uri.parse(
          'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getSubscribed?userId=${userId}');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> subscriptions = json.decode(response.body);
        
        // Transform subscriptions to list of IDs where any preference is true
        return subscriptions.where((sub) {
          final preferences = sub['preferences'] as Map<String, dynamic>;
          return preferences.values.any((value) => value == true);
        }).map((sub) => sub['id']).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } else {
      return [];
    }
  }
}
