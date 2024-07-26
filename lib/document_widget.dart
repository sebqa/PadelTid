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
                                  return ListTile(
                                            leading: Text(
                                              '${document.time}',
                                              //make text black with a white stroke
                                              style: TextStyle(
                                                fontSize: 26.0,
                                                color: Theme.of(context).colorScheme.onPrimary,
                                              ),                           
                                            ),
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                              
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(' ${document.windSpeed} m/s '),
                                                          Icon(Icons.air),
                                          
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(' ${document.airTemperature}°C '),
                                                          Icon(Icons.thermostat_outlined),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(padding: EdgeInsets.only(left: 24.0)),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      
                                                      Row(
                                                        children: [
                                                          Text(' ${document.precipitationProbability}%'),
                                                          Icon(Icons.umbrella),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(' ${document.availableSlots} '),
                                                          Icon(Icons.sports_baseball),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                            ),
                                          
                                  );
                                }

}
