import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:http/http.dart' as http;

class DocumentService {
  Future<List<Document>> fetchDocuments(
      double windSpeed,
      double precipitationProbability,
      bool showUnavailableSlots,
      bool fetchRecommended,
      List<String> selectedLocations) async {
    List<dynamic> subscribedDocs = [];

    //get subscribedDocs
    if (fetchRecommended) {
    } else {
      subscribedDocs = await getSubscribedDocs();
    }
    
    // Build query parameters including selected locations
    final queryParams = {
      'wind_speed_threshold': windSpeed.toString(),
      'precipitation_probability_threshold': precipitationProbability.toString(),
      'showUnavailableSlots': showUnavailableSlots.toString(),
      'locations': selectedLocations.join(','), // Add selected locations
    };
    
    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid')
        .replace(queryParameters: queryParams);
        
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => Document.fromJson(json, subscribedDocs))
          .where((doc) => 
            // If no locations selected, show all. Otherwise filter by selected locations
            selectedLocations.isEmpty || 
            doc.clubs.keys.any((club) => selectedLocations.contains(club)))
          .toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  Future<List<dynamic>> getSubscribedDocs() async {
    //http request to get all subscribed docs

    //if user is signed in
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      Uri url = Uri.parse(
          'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getSubscribed?userId=${userId}');

      final response = await http.get(url);
      print(response.body);
      if (response.statusCode == 200) {
        //parse json
        List<dynamic> subscribedDocs = json.decode(response.body);
        return subscribedDocs;
      } else {
        throw Exception('Failed to load documents');
      }
    } else {
      return [];
    }
  }
}
