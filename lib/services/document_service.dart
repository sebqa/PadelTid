import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/document.dart';

class DocumentService {
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
}
