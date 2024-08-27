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
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.recommend, color: Theme.of(context).colorScheme.primaryContainer),
                SizedBox(width: 8),
                Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110, // Adjust this value as needed
            child: RecommendedDocumentsListView(
              recommendedDocuments: documents,
            ),
          ),
        ],
      ),
    );
  }
}
