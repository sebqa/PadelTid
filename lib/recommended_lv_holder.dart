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
    return Container(
      child: Column(
        children: [
                    Padding(padding: EdgeInsets.all(10.0),),

              Container(
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              
          ),
    
          SizedBox(
              height: 100, // Set the height of the horizontal ListView
              child:RecommendedDocumentsListView(
                      recommendedDocuments: documents,
                    )
            ),
          
    
        ],
      ),
    );
  }
}
