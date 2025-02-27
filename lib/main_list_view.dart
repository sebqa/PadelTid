import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/document_widget.dart';
import 'widgets/skeleton_widgets.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';

class MainListView extends StatefulWidget {
  const MainListView({
    super.key,
    required this.groupedDocuments,
    required this.onFilterTap,
  });

  final Map<String, List<Document>> groupedDocuments;
  final VoidCallback onFilterTap;

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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return ListView(
      // This makes the ListView take only the space it needs
      shrinkWrap: true,
      // Disable scrolling in this ListView since parent handles it
      physics: NeverScrollableScrollPhysics(),
      children: widget.groupedDocuments.entries.map((entry) {
        final date = entry.key;
        final documentsForDate = entry.value;
        final isExpanded = expandedDates.contains(date);
        final parsedDate = DateTime.parse(date);

        documentsForDate.sort((a, b) => a.time.compareTo(b.time));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: InkWell(
                onTap: () => _toggleDate(date),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.05)
                        : Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              parsedDate.day.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              _getShortMonthName(parsedDate.month, context),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getWeekdayName(parsedDate.weekday, context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${documentsForDate.length} ${TranslationHelper.translate('slots', localeProvider.locale.languageCode)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 24,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded)
              ...documentsForDate
                  .map((doc) => DocumentWidget(document: doc))
                  .toList(),
          ],
        );
      }).toList(),
    );
  }

  String _getDisplayDate(DateTime date, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return localizations.translate('today');
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return localizations.translate('tomorrow');
    } else {
      return '${_getWeekdayName(date.weekday, context)}, ${date.day}/${date.month}';
    }
  }

  String _getWeekdayName(int weekday, BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;
    const weekdayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return TranslationHelper.translate(weekdayKeys[weekday - 1], languageCode);
  }

  String _getShortMonthName(int month, BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;
    const monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    ];
    return TranslationHelper.translate(monthKeys[month - 1], languageCode);
  }
}
