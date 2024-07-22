import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';

class RecommendedDocumentWidget extends StatelessWidget {
  final Document document;

  RecommendedDocumentWidget(this.document);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //show the proprties date, windSpeed and airTemperature with some style
          Text('Date: ${document.date}'),
          Text('Wind speed: ${document.windSpeed} m/s'),
          Text('Temperature: ${document.airTemperature}°C'), 
          
          
          // Add more properties as needed
        ],
      ),
    );
  }
}