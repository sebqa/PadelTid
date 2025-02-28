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

  factory PadelBallBehavior.calculate(double airPressure, double humidity,
      double temperature, double windSpeed) {
    // Base reference values
    const standardPressure = 1013.25; // hPa (standard sea level pressure)
    const standardHumidity = 50.0; // %
    const standardTemp = 8.3; // °C
    const standardWindSpeed = 2.0; // m/s - light breeze

    // Calculate relative pressure (ratio of standard to actual)
    // Lower external air pressure = higher internal-to-external pressure difference
    final pressureDifferential = standardPressure / airPressure;

    // Calculate moisture absorption factor (increases with humidity)
    // Higher humidity = heavier, slower ball
    final moistureAbsorptionFactor =
        1 + ((humidity - standardHumidity) * 0.003);

    // Calculate ball behaviors with bounds checking

    // Ball weight (100 = standard, higher means heavier)
    // Weight increases with humidity as ball absorbs moisture
    double ballWeight = 100 * moistureAbsorptionFactor;
    ballWeight = _boundValue(ballWeight, 80, 120);

    // Ball speed (100 = standard, higher means faster)
    // Speed increases with lower air pressure (higher pressure differential)
    // Speed decreases with higher humidity (heavier ball)
    // Speed increases slightly with higher temperature (less air resistance)
    double tempFactor = min(temperature / standardTemp, 1.2);
    double ballSpeed =
        100 * (pressureDifferential * tempFactor / moistureAbsorptionFactor);
    ballSpeed = _boundValue(ballSpeed, 80, 120);

    // Ball bounce (100 = standard, higher means higher bounce)
    // Bounce increases with lower air pressure (higher pressure differential)
    // Bounce decreases with higher humidity (softer, less elastic ball)
    double ballBounce = 100 *
        (pressureDifferential * 0.6 + (1 / moistureAbsorptionFactor) * 0.4);
    ballBounce = _boundValue(ballBounce, 80, 120);

    // Ball control (100 = standard, higher is better control)
    // Control is better when conditions are close to standard
    // Control is significantly reduced by high wind speeds
    final humidityDeviation = (humidity - standardHumidity).abs() / 50;
    final pressureDeviation =
        (airPressure - standardPressure).abs() / standardPressure;
    final tempDeviation = (temperature - standardTemp).abs() / 20;

    // Wind factor: exponential decrease in control as wind increases beyond standard
    final windFactor = windSpeed <= standardWindSpeed
        ? 0.0
        : min(pow(windSpeed / standardWindSpeed - 1, 1.5) * 0.5, 0.6);

    double ballControl = 100 *
        (1 -
            (humidityDeviation * 0.2 +
                pressureDeviation * 0.2 +
                tempDeviation * 0.1 +
                windFactor));

    ballControl = _boundValue(ballControl, 80, 120);

    return PadelBallBehavior(
      ballWeight: ballWeight,
      ballSpeed: ballSpeed,
      ballBounce: ballBounce,
      ballControl: ballControl,
      playingStrategy:
          _determineStrategy(ballWeight, ballSpeed, ballBounce, windSpeed),
      recommendedBallType:
          _recommendBallType(airPressure, humidity, temperature, windSpeed),
    );
  }

  static double _calculateVaporPressure(double temperature, double humidity) {
    // Magnus-Tetens formula for saturation vapor pressure
    final saturationVaporPressure =
        6.1078 * exp((17.27 * temperature) / (temperature + 237.3));
    return (humidity / 100) * saturationVaporPressure;
  }

  static String _determineStrategy(double ballWeight, double ballSpeed,
      double ballBounce, double windSpeed) {
    // Prioritize wind-based strategy if wind is high
    if (windSpeed > 5.0) {
      return 'strategy_windy';
    }

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

  static String _recommendBallType(double airPressure, double humidity,
      double temperature, double windSpeed) {
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
    } else if (windSpeed > 5.0) {
      return 'ball_wind_resistant';
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

  // Helper function to keep values within desired range
  static double _boundValue(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
