import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/document_widget.dart';

class MainListView extends StatefulWidget {
  const MainListView({
    super.key,
    required this.groupedDocuments,
  });

  final Map<String, List<Document>> groupedDocuments;

  @override
  State<MainListView> createState() => _MainListViewState();
}

class _MainListViewState extends State<MainListView> {
  Set<String> expandedDates = {};

  void _toggleDate(String date) {
    setState(() {
      if (expandedDates.contains(date)) {
        expandedDates.remove(date);
      } else {
        expandedDates.add(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Timeslots',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.tune, color: Colors.black),
                  onPressed: () => showSettingsDialog(),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.groupedDocuments.length,
            itemBuilder: (context, index) {
              final date = widget.groupedDocuments.keys.toList()[index];
              final documentsForDate = widget.groupedDocuments[date]!;
              final parsedDate = DateTime.parse(date);
              final isExpanded = expandedDates.contains(date);
              
              documentsForDate.sort((a, b) => a.time.compareTo(b.time));
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _toggleDate(date),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDisplayDate(parsedDate),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${documentsForDate.length} slots',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    ...documentsForDate.map((doc) => DocumentWidget(document: doc)).toList(),
                ],
              );
            },
          ),
        ],
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
