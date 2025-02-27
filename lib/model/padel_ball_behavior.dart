import 'dart:math';

class PadelBallBehavior {
  final double ballWeight;
  final double ballSpeed;
  final double ballBounce;
  final double ballControl;
  final String playingStrategy;
  final String recommendedBallType;

  PadelBallBehavior({
    required this.ballWeight,
    required this.ballSpeed,
    required this.ballBounce,
    required this.ballControl,
    required this.playingStrategy,
    required this.recommendedBallType,
  });

  factory PadelBallBehavior.calculate(
      double airPressure, double humidity, double temperature) {
    // Base reference values
    const standardPressure = 1013.25; // hPa (standard sea level pressure)
    const standardHumidity = 50.0; // %
    const standardTemp = 20.0; // °C

    // Calculate moisture absorption factor (increases with humidity)
    final moistureAbsorptionFactor =
        1 + ((humidity - standardHumidity) * 0.003);

    // Air density calculation factors
    final temperatureKelvin = temperature + 273.15;
    final vaporPressure = _calculateVaporPressure(temperature, humidity);
    final dryAirPressure = airPressure - vaporPressure;

    // Simplified air density calculation (kg/m³)
    final airDensity = (dryAirPressure * 0.0289652 + vaporPressure * 0.018016) /
        (8.31447 * temperatureKelvin);

    // Reference air density at standard conditions
    const standardAirDensity = 1.225; // kg/m³

    // Calculate relative air density (compared to standard)
    final airDensityRatio = airDensity / standardAirDensity;

    // Calculate ball behaviors
    // Ball weight (100 = standard, higher means heavier)
    final ballWeight = 100 * moistureAbsorptionFactor;

    // Ball speed (100 = standard, higher means faster)
    final ballSpeed =
        100 * (1 / (airDensityRatio * sqrt(moistureAbsorptionFactor)));

    // Ball bounce (100 = standard, higher means higher bounce)
    final pressureDifferential = airPressure / standardPressure;
    final ballBounce = 100 *
        ((1 / moistureAbsorptionFactor) * 0.7 + pressureDifferential * 0.3);

    // Ball control (100 = standard, higher is better control)
    final humidityDeviation = (humidity - standardHumidity).abs() / 50;
    final pressureDeviation =
        (airPressure - standardPressure).abs() / standardPressure;
    final tempDeviation = (temperature - standardTemp).abs() / 20;
    final ballControl = 100 *
        (1 -
            (humidityDeviation * 0.4 +
                pressureDeviation * 0.3 +
                tempDeviation * 0.3));

    return PadelBallBehavior(
      ballWeight: ballWeight,
      ballSpeed: ballSpeed,
      ballBounce: ballBounce,
      ballControl: ballControl,
      playingStrategy: _determineStrategy(ballWeight, ballSpeed, ballBounce),
      recommendedBallType:
          _recommendBallType(airPressure, humidity, temperature),
    );
  }

  static double _calculateVaporPressure(double temperature, double humidity) {
    // Magnus-Tetens formula for saturation vapor pressure
    final saturationVaporPressure =
        6.1078 * exp((17.27 * temperature) / (temperature + 237.3));
    return (humidity / 100) * saturationVaporPressure;
  }

  static String _determineStrategy(
      double ballWeight, double ballSpeed, double ballBounce) {
    if (ballWeight > 110 && ballSpeed < 90 && ballBounce < 90) {
      return 'strategy_aggressive';
    } else if (ballWeight < 95 && ballSpeed > 110 && ballBounce > 110) {
      return 'strategy_defensive';
    } else if (ballBounce < 95 && ballSpeed < 95) {
      return 'strategy_technical';
    } else {
      return 'strategy_balanced';
    }
  }

  static String _recommendBallType(
      double airPressure, double humidity, double temperature) {
    if (airPressure < 900) {
      return 'ball_high_altitude';
    } else if (humidity > 70) {
      return 'ball_moisture_resistant';
    } else if (humidity < 30) {
      return 'ball_standard_pressurized';
    } else if (temperature > 30) {
      return 'ball_heat_resistant';
    } else if (temperature < 10) {
      return 'ball_cold_weather';
    } else {
      return 'ball_standard_tournament';
    }
  }

  String getSpeedDescription() {
    if (ballSpeed > 110) return 'ball_speed_much_faster';
    if (ballSpeed > 105) return 'ball_speed_faster';
    if (ballSpeed > 95) return 'ball_speed_normal';
    if (ballSpeed > 90) return 'ball_speed_slower';
    return 'ball_speed_much_slower';
  }

  String getBounceDescription() {
    if (ballBounce > 110) return 'ball_bounce_much_higher';
    if (ballBounce > 105) return 'ball_bounce_higher';
    if (ballBounce > 95) return 'ball_bounce_normal';
    if (ballBounce > 90) return 'ball_bounce_lower';
    return 'ball_bounce_much_lower';
  }

  String getControlDescription() {
    if (ballControl > 110) return 'ball_control_excellent';
    if (ballControl > 105) return 'ball_control_good';
    if (ballControl > 95) return 'ball_control_normal';
    if (ballControl > 90) return 'ball_control_challenging';
    return 'ball_control_difficult';
  }
}
