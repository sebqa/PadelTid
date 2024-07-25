import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:adv_flutter_weather/flutter_weather_bg.dart';



class DocumentWidget extends StatelessWidget {
  const DocumentWidget({
    Key? key,
    required this.document,
  }) : super(key: key);

  final Document document;

  @override
  Widget build(BuildContext context) {
    WeatherType weatherType;
    
    if (document.precipitationProbability == 0) {
      weatherType = WeatherType.sunny;
    } else if (document.precipitationProbability >= 1 && document.precipitationProbability <= 10) {
      weatherType = WeatherType.cloudy;
    } else if (document.precipitationProbability >= 20 && document.precipitationProbability <= 50) {
      weatherType = WeatherType.lightRainy;
       } else if (document.precipitationProbability >= 60 && document.precipitationProbability <= 70) {
      weatherType = WeatherType.lightRainy;
    } else {
      weatherType = WeatherType.heavyRainy;
    }
    
                                  return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipPath(
        child: Stack(
          children: [
            WeatherBg(
              weatherType: weatherType,
              width: MediaQuery.of(context).size.width,
              height: 100,
            ),Column(
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
          ],
        ),
      ),
                                  );
                                }

}