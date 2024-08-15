import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:http/http.dart' as http;

class DocumentService {
  Future<List<Document>> fetchDocuments(double windSpeed, double precipitationProbability,
      bool showUnavailableSlots, bool fetchRecommended) async {
          List<dynamic> subscribedDocs = [];

        //get subscribedDocs
        if(fetchRecommended){
          
        } else{
              subscribedDocs = await getSubscribedDocs();
        }
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