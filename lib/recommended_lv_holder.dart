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
    documents.removeWhere((document) =>
        int.parse(document.time.split(':')[0]) < 10 ||
        int.parse(document.time.split(':')[0]) > 20);
    //randomize order of documents
    documents.shuffle();

    // Get screen size
    final screenHeight = MediaQuery.of(context).size.height;
    // Calculate responsive height (approximately 16-20% of screen height)
    final listViewHeight = screenHeight * 0.13;

    return Container(
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Text(
                  'Recommended',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: listViewHeight,
            child: RecommendedDocumentsListView(
              recommendedDocuments: documents,
            ),
          ),
        ],
      ),
    );
  }
}
