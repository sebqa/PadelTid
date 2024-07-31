import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/model/document.dart';

class MainListView extends StatelessWidget {
  const MainListView({
    super.key,
    required this.groupedDocuments,
    required this.weekdayName,
  });

  final Map<String, List<Document>> groupedDocuments;
  final List<String> weekdayName;

  @override
  Widget build(BuildContext context) {
    return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0,8.0,8.0,0),
                    child: Container(
                      decoration:  BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25), // Shadow color with opacity
                            spreadRadius: 1, // Spread radius
                            blurRadius: 4, // Blur radius
                            offset: Offset(0, -1), // Offset (x, y), negative y to have the shadow on top
                          ),
                        ],// Set your desired background color
                      ),
                      child: ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: groupedDocuments.length,
      itemBuilder: (context, index) {
        final date = groupedDocuments.keys.toList()[index];
        final documentsForDate = groupedDocuments[date]!;
        final parsedDate = DateTime.parse(date);
    
                  documentsForDate.sort((a, b) => a.time.compareTo(b.time));
                  
                  final formattedDate = '${weekdayName[parsedDate
                      .weekday - 1]}, '
                      '${parsedDate.day}/${parsedDate
                      .month}/${parsedDate.year}';
        return Column(
          children: [
            ExpansionTile(
              shape: Border(),
              subtitle: Text('${documentsForDate.length} timeslots'),
              title: Row(
                children: [
                  Icon(
                    color: Theme.of(context).colorScheme.tertiary,
                    Icons.calendar_today),
                  Text(' $formattedDate'),
                ],
              ),
              children: [
                ListViewbuilder(documentsForDate: documentsForDate),
              ],
            ),
            Divider(thickness: 0.5,)
          ],
        );
      },
    
    ),
                  ),
                ),
              );
  }
}
