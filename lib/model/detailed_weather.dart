import 'dart:math';
import 'package:flutter_application_1/model/padel_ball_behavior.dart';

class DetailedWeather {
  final DateTime time;
  final double airTemperature;
  final double windSpeed;
  final double windDirection;
  final double precipitation;
  final double humidity;
  final double airPressure;
  final String symbolCode;
  final double precipitationProbability;

  PadelBallBehavior get padelBallBehavior =>
      PadelBallBehavior.calculate(airPressure, humidity, airTemperature);

  DetailedWeather({
    required this.time,
    required this.airTemperature,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.humidity,
    required this.airPressure,
    required this.symbolCode,
    required this.precipitationProbability,
  });

  factory DetailedWeather.fromJson(Map<String, dynamic> json) {
    final instant = json['data']['instant']['details'];
    final next1Hour = json['data']['next_1_hours'];

    return DetailedWeather(
      time: DateTime.parse(json['time']),
      airTemperature: instant['air_temperature'].toDouble(),
      windSpeed: instant['wind_speed'].toDouble(),
      windDirection: instant['wind_from_direction'].toDouble(),
      precipitation: next1Hour != null && next1Hour['details'] != null
          ? next1Hour['details']['precipitation_amount'].toDouble()
          : 0.0,
      humidity: instant['relative_humidity'].toDouble(),
      airPressure: instant['air_pressure_at_sea_level'].toDouble(),
      symbolCode: next1Hour != null && next1Hour['summary'] != null
          ? next1Hour['summary']['symbol_code']
          : 'cloudy',
      precipitationProbability:
          next1Hour != null && next1Hour['details'] != null
              ? next1Hour['details']['probability_of_precipitation'].toDouble()
              : 0.0,
    );
  }
}
