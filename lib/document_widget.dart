import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:weather_animation/weather_animation.dart';

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
                                          
                                          leading: Text(
                                            '${document.time}',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          title: SizedBox(
                                            width: 200,
                                            child: Row(
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
                                          ),
                                        ),
                                        
                                      ],
                                    ),
                                  );
                                }

}