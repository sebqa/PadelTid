import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/model/document.dart';

class MainListView extends StatelessWidget {
  const MainListView({
    super.key,
    required this.groupedDocuments,
  });

  final Map<String, List<Document>> groupedDocuments;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: groupedDocuments.length,
        itemBuilder: (context, index) {
          final date = groupedDocuments.keys.toList()[index];
          final documentsForDate = groupedDocuments[date]!;
          final parsedDate = DateTime.parse(date);
          
          documentsForDate.sort((a, b) => a.time.compareTo(b.time));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  _getDisplayDate(parsedDate),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ...documentsForDate.map((doc) => DocumentWidget(document: doc)),
            ],
          );
        },
      ),
    );
  }

  String _getDisplayDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return '${_getWeekdayName(date.weekday)}, ${date.day}/${date.month}';
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }
}
