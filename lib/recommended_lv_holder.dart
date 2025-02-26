import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/recommended_documents_lv.dart';
import 'widgets/skeleton_widgets.dart';

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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: listViewHeight,
        child: RecommendedDocumentsListView(
          recommendedDocuments: documents,
        ),
      ),
    );
  }
}
