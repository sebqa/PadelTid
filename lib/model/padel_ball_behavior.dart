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

    // --------- PRESSURE EFFECT ON BALL ---------
    // Higher atmospheric pressure = slower ball
    // Calculate as a ratio, where:
    // - pressure ratio > 1.0 means pressure is higher than standard (slower ball)
    // - pressure ratio < 1.0 means pressure is lower than standard (faster ball)
    final pressureRatio = airPressure / standardPressure;

    // Convert to speed effect (inverse relationship)
    // When pressure is higher (ratio > 1), speed factor should be < 1
    final pressureSpeedFactor = 2 - pressureRatio; // Inverting effect

    // --------- HUMIDITY EFFECT ON BALL ---------
    // Higher humidity = heavier, slower ball due to moisture absorption
    // 0% humidity would be 0.85, 100% humidity would be 1.15 (±15% effect)
    final humidityFactor = 0.85 + (humidity / 100) * 0.3;

    // --------- TEMPERATURE EFFECT ON BALL ---------
    // Higher temperature = less dense air = faster ball
    // Calculate relative to standard, with limits
    // (Temperature has less impact than pressure or humidity)
    final relativeTemp = temperature / standardTemp;
    final tempFactor = max(0.9, min(1.1, 0.95 + relativeTemp * 0.05));

    // --------- CALCULATE BALL CHARACTERISTICS ---------

    // WEIGHT: Higher humidity = heavier ball
    double ballWeight = 100 * humidityFactor;

    // SPEED: Affected by all factors
    // Lower pressure = faster ball
    // Lower humidity = faster ball
    // Higher temperature = faster ball
    double ballSpeed =
        100 * (pressureSpeedFactor / humidityFactor) * tempFactor;

    // BOUNCE: Similar factors as speed
    double ballBounce = 100 * (pressureSpeedFactor / humidityFactor) * 0.8 + 20;

    // CONTROL: Better in stable, standard conditions
    // Wind has major impact on control
    final humidityDeviation = (humidity - standardHumidity).abs() / 50;
    final pressureDeviation =
        (airPressure - standardPressure).abs() / standardPressure;
    final tempDeviation = (temperature - standardTemp).abs() / 20;

    // Wind factor: exponential decrease in control as wind increases
    final windFactor = windSpeed <= standardWindSpeed
        ? 0.0
        : min(pow(windSpeed / standardWindSpeed - 1, 1.5) * 0.5, 0.6);

    double ballControl = 100 *
        (1 -
            (humidityDeviation * 0.2 +
                pressureDeviation * 0.2 +
                tempDeviation * 0.1 +
                windFactor));

    // Ensure all values stay within our scale
    ballWeight = _boundValue(ballWeight, 80, 120);
    ballSpeed = _boundValue(ballSpeed, 80, 120);
    ballBounce = _boundValue(ballBounce, 80, 120);
    ballControl = _boundValue(ballControl, 80, 120);

    // Debug print showing key values
    print(
        "Weather - P: $airPressure hPa, H: $humidity%, T: $temperature°C, W: $windSpeed m/s");
    print(
        "Factors - P: $pressureRatio/$pressureSpeedFactor, H: $humidityFactor, T: $tempFactor");
    print(
        "Results - Speed: $ballSpeed, Bounce: $ballBounce, Control: $ballControl");

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
    if (ballSpeed >= 110) return 'ball_speed_much_faster';
    if (ballSpeed >= 105) return 'ball_speed_faster';
    if (ballSpeed > 95 && ballSpeed < 105) return 'ball_speed_normal';
    if (ballSpeed >= 90) return 'ball_speed_slower';
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
