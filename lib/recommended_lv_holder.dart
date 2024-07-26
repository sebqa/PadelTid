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
      decoration:  BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25), // Shadow color with opacity
            spreadRadius: 1, // Spread radius
            blurRadius: 4, // Blur radius
            offset: Offset(0, -1), // Offset (x, y), negative y to have the shadow on top
          ),
        ],// Set your desired background color
      ),
      
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: EdgeInsets.only(left: 8.0)),
              Container(
                
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    
          SizedBox(
              height: 120, // Set the height of the horizontal ListView
              child: documents != null
                  ? RecommendedDocumentsListView(
                      recommendedDocuments: documents,
                    )
                  : CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
            ),
          
    
        ],
      ),
    );
  }
}
