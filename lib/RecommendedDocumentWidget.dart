import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';

class RecommendedDocumentWidget extends StatelessWidget {
  final Document document;

  RecommendedDocumentWidget(this.document);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(color: Colors.black, width: 1),
          
          boxShadow: [
            BoxShadow(
               color: Colors.black.withOpacity(0.25), // Shadow color with opacity
                                    spreadRadius: 1, // Spread radius
                                    blurRadius: 4, // Blur radius
                                    offset: Offset(0, -1), 
            ),
          ]
        ),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //show the proprties date, windSpeed and airTemperature with some style
            //check if date is today
        Text('Date: ${_getDisplayDate(document.date)}'),
            Text('Time: ${document.time}'),
            Text('Wind speed: ${document.windSpeed} m/s'),
            Text('Temperature: ${document.airTemperature}°C'), 
        
            
            // Add more properties as needed
          ],
        ),
      ),
    );
  }
}
String _getDisplayDate(String dateStr) {
  DateTime now = DateTime.now();
  DateTime date = DateTime.parse(dateStr);
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
    return 'Tomorrow';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}