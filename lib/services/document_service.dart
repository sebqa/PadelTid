import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/document.dart';

class DocumentService {
  Future<Document> getDocumentById(String documentId) async {
    try {
      // Use the Lambda Function URL instead of API Gateway
      final response = await http.get(
        Uri.parse(
            'https://laseojfvjff4ms5nagckrhrd2u0cprtj.lambda-url.eu-north-1.on.aws/?documentId=$documentId'),
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
