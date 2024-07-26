import 'package:flutter/material.dart';
import 'package:flutter_application_1/RecommendedDocumentWidget.dart';
import 'package:flutter_application_1/model/document.dart';

class RecommendedDocumentsListView extends StatelessWidget {
  final List<Document> recommendedDocuments;

  RecommendedDocumentsListView({required this.recommendedDocuments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Container(
        
        child: SizedBox(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedDocuments.length,
            separatorBuilder: (_, __) => SizedBox(width: 0),
            itemBuilder: (context, index) {
              return RecommendedDocumentWidget(recommendedDocuments[index]);
            },
          ),
        ),
      ),
    );
  }

}