import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';

class DocumentWidget extends StatelessWidget {
  const DocumentWidget({
    Key? key,
    required this.document,
  }) : super(key: key);

  final Document document;

  @override
  Widget build(BuildContext context) {
                                  return Theme(
                                    data: ThemeData(
                                      textTheme: TextTheme(
                                        titleMedium: TextStyle(fontSize: 18,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer),

                                      )
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Row(
                                            children: [
                                              Icon(Icons.schedule),
                                              Text(' ${document.time}'),
                                            ],
                                          ),
                                          subtitle: Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.air),
                                                      Text(' ${document
                                                          .windSpeed} m/s'),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons
                                                          .thermostat_outlined),
                                                      Text(' ${document
                                                          .airTemperature}°C'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.umbrella),
                                                      Text(' ${document
                                                          .precipitationProbability}%'),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.calendar_today),
                                                      Text(' ${document
                                                          .availableSlots ?? "0"}'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

}