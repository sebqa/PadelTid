import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/recommended_documents_lv.dart';

class recommended_lv_holder extends StatelessWidget {
  const recommended_lv_holder({
    super.key,
    required this.documents,
  });

  final List<Document> documents;

  @override
  Widget build(BuildContext context) {
    //drop documents where time is not between 10:00:00 and 20:00:00
    documents.removeWhere((document) => int.parse(document.time.split(':')[0]) < 10 || int.parse(document.time.split(':')[0]) > 20);
    //randomize order of documents
    documents.shuffle();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: SizedBox(
            height: 100, // Increased height for better visibility
        child: RecommendedDocumentsListView(
          recommendedDocuments: documents,
        ),
      ),
    );
  }
}
