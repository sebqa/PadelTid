import 'dart:convert';

import 'package:flutter_application_1/model/document.dart';
import 'package:http/http.dart' as http;

class DocumentService {
  Future<List<Document>> fetchDocuments(double windSpeed, double precipitationProbability,
      bool showUnavailableSlots, List<String> subscribedDocs) async {
    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid?wind_speed_threshold=$windSpeed&precipitation_probability_threshold=$precipitationProbability&showUnavailableSlots=$showUnavailableSlots');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => Document.fromJson(json, subscribedDocs))
          .toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }
}