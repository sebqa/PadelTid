import 'package:flutter/material.dart';
import 'package:flutter_application_1/RecommendedDocumentWidget.dart';
import 'package:flutter_application_1/model/document.dart';

class RecommendedDocumentsListView extends StatelessWidget {
  final List<Document> recommendedDocuments;

  RecommendedDocumentsListView({required this.recommendedDocuments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Set the height of the horizontal ListView
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedDocuments.length,
        itemBuilder: (context, index) {
          return RecommendedDocumentWidget(recommendedDocuments[index]);
        },
      ),
    );
  }
}