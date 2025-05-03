import 'package:flutter_application_1/widgets/notification_preferences_dialog.dart';
import 'dart:math';

class ClubAvailability {
  final String clubId;
  final String clubName;
  final String clubUrl;
  final int availableSlots;
  final int totalCourts;
  final Weather weather;
  final String latitude;
  final String longitude;

  ClubAvailability({
    required this.clubId,
    required this.clubName,
    required this.clubUrl,
    required this.availableSlots,
    required this.totalCourts,
    required this.weather,
    this.latitude = '',
    this.longitude = '',
  });

  factory ClubAvailability.fromJson(Map<String, dynamic> json) {
    try {
      // Make sure we have weather data, otherwise provide defaults
      Map<String, dynamic> weatherData = {};
      if (json.containsKey('weather') &&
          json['weather'] is Map<String, dynamic>) {
        weatherData = json['weather'] as Map<String, dynamic>;
      }

      return ClubAvailability(
        clubId: json['club_id'] is String ? json['club_id'] : '',
        clubName: json['club_name'] is String ? json['club_name'] : '',
        clubUrl: json['club_url'] is String ? json['club_url'] : '',
        availableSlots:
            json['available_slots'] is int ? json['available_slots'] : 0,
        totalCourts: json['total_courts'] is int ? json['total_courts'] : 0,
        weather: weatherData.isNotEmpty
            ? Weather.fromJson(weatherData)
            : Weather.defaultWeather(),
        latitude: json['latitude'] is String ? json['latitude'] : '',
        longitude: json['longitude'] is String ? json['longitude'] : '',
      );
    } catch (e) {
      print('[Error] Error in ClubAvailability.fromJson: $e for JSON: $json');
      // Return a default club availability
      return ClubAvailability(
        clubId: '',
        clubName: 'Unknown Club',
        clubUrl: '',
        availableSlots: 0,
        totalCourts: 0,
        weather: Weather.defaultWeather(),
      );
    }
  }
}

class Weather {
  final double windSpeed;
  final double precipitationProbability;
  final double airTemperature;
  final String symbolCode;

  Weather({
    required this.windSpeed,
    required this.precipitationProbability,
    required this.airTemperature,
    required this.symbolCode,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      return Weather(
        windSpeed:
            json['wind_speed'] is num ? json['wind_speed'].toDouble() : 0.0,
        precipitationProbability: json['precipitation_probability'] is num
            ? json['precipitation_probability'].toDouble()
            : 0.0,
        airTemperature: json['air_temperature'] is num
            ? json['air_temperature'].toDouble()
            : 0.0,
        symbolCode: json['symbol_code'] is String
            ? json['symbol_code']
            : 'clearsky_day',
      );
    } catch (e) {
      print('[Error] Error in Weather.fromJson: $e for JSON: $json');
      return Weather.defaultWeather();
    }
  }

  static Weather defaultWeather() {
    // Implementation of defaultWeather method
    // This is a placeholder and should be replaced with the actual implementation
    return Weather(
      windSpeed: 0.0,
      precipitationProbability: 0.0,
      airTemperature: 0.0,
      symbolCode: 'clearsky_day',
    );
  }
}

class Document {
  final String date;
  final String time;
  final Map<String, ClubAvailability> clubs;
  bool? _followed;
  NotificationPreferences? notificationPreferences;
  final List<String> selectedLocations;

  Document({
    required this.date,
    required this.time,
    required this.clubs,
    required this.selectedLocations,
    bool? followed,
    this.notificationPreferences,
  }) : _followed = followed;

  bool? get followed => _followed;
  set followed(bool? value) => _followed = value;

  // Get weather from first available selected location or first available club
  Weather? get weather {
    if (clubs.isEmpty) return null;

    if (selectedLocations.isNotEmpty) {
      for (var location in selectedLocations) {
        if (clubs.containsKey(location)) {
          return clubs[location]!.weather;
        }
      }
    }
    return clubs.values.first.weather;
  }

  double get airTemperature => weather?.airTemperature ?? 0.0;
  double get precipitationProbability =>
      weather?.precipitationProbability ?? 0.0;
  double get windSpeed => weather?.windSpeed ?? 0.0;
  String get symbolCode => weather?.symbolCode ?? 'clearsky_day';

  int get totalAvailableSlots =>
      clubs.values.fold(0, (sum, club) => sum + club.availableSlots);

  int get totalClubs => selectedLocations.isEmpty
      ? clubs.length
      : clubs.keys.where((club) => selectedLocations.contains(club)).length;

  factory Document.fromJson(
      Map<String, dynamic> json, List<dynamic> followedDocs,
      {List<String> selectedLocations = const []}) {
    try {
      // Ensure we have required fields
      if (!json.containsKey('date') || !json.containsKey('time')) {
        print('[Error] Document JSON missing required fields: $json');
        throw FormatException('Document JSON missing required fields');
      }

      // Handle time field safely
      String timeStr = '';
      if (json['time'] is String) {
        timeStr = json['time'];
        // If time is longer than 5 characters, truncate it
        if (timeStr.length > 5) {
          timeStr = timeStr.substring(0, 5);
        }
      } else {
        print('[Error] Invalid time format in document: ${json['time']}');
        timeStr = '00:00'; // Default time if invalid
      }

      Map<String, ClubAvailability> clubs = {};
      if (json.containsKey('clubs') && json['clubs'] is Map<String, dynamic>) {
        (json['clubs'] as Map<String, dynamic>).forEach((key, value) {
          // Skip null clubs or those that are not Maps
          if (value != null && value is Map<String, dynamic>) {
            try {
              clubs[key] = ClubAvailability.fromJson(value);
            } catch (e) {
              print('[Error] Failed to parse club data for $key: $e');
              // Continue with next club
            }
          }
        });
      }

      // First check if 'followed' is directly available in the JSON (from the API)
      bool? isFollowed = json.containsKey('followed') ? json['followed'] : null;

      // If not available in JSON, fall back to checking followedDocs (legacy approach)
      if (isFollowed == null && followedDocs.isNotEmpty) {
        try {
          // Create document ID in the format YYYYMMDDHHMMSS
          final String dateStr =
              json['date'] is String ? json['date'].replaceAll('-', '') : '';
          final String timeSubstr = timeStr.length >= 5
              ? timeStr.substring(0, 5).replaceAll(':', '')
              : '0000';
          final docId = dateStr + timeSubstr + "00";

          // Find follow data for this document
          final followData = followedDocs.firstWhere(
            (follow) => follow is Map && follow['id'] == docId,
            orElse: () => null,
          );

          isFollowed = followData != null;
        } catch (e) {
          print('[Error] Error checking followed status: $e');
          isFollowed = false;
        }
      }

      // Get preferences - first try from direct JSON, then fallback to followedDocs
      NotificationPreferences? preferences;
      if (json.containsKey('preferences') &&
          json['preferences'] is Map<String, dynamic>) {
        try {
          // Get preferences directly from the API response
          final prefsJson = json['preferences'] as Map<String, dynamic>;
          preferences = NotificationPreferences(
            notifyOnWeatherChange: prefsJson['notifyOnWeatherChange'] == true,
            notifyWhenAvailable: prefsJson['notifyWhenAvailable'] == true,
            notifyWhenOneLeft: prefsJson['notifyWhenOneLeft'] == true,
            notifyWhenFull: prefsJson['notifyWhenFull'] == true,
          );
        } catch (e) {
          print('[Error] Error parsing preferences from direct JSON: $e');
        }
      } else if (followedDocs.isNotEmpty) {
        try {
          // Legacy approach - get from followedDocs
          // Create document ID for lookup
          final String dateStr =
              json['date'] is String ? json['date'].replaceAll('-', '') : '';
          final String timeSubstr = timeStr.length >= 5
              ? timeStr.substring(0, 5).replaceAll(':', '')
              : '0000';
          final docId = dateStr + timeSubstr + "00";

          final followData = followedDocs.firstWhere(
            (follow) => follow is Map && follow['id'] == docId,
            orElse: () => null,
          );

          if (followData != null &&
              followData is Map &&
              followData['preferences'] is Map<String, dynamic>) {
            final prefsJson = followData['preferences'] as Map<String, dynamic>;
            preferences = NotificationPreferences(
              notifyOnWeatherChange: prefsJson['notifyOnWeatherChange'] == true,
              notifyWhenAvailable: prefsJson['notifyWhenAvailable'] == true,
              notifyWhenOneLeft: prefsJson['notifyWhenOneLeft'] == true,
              notifyWhenFull: prefsJson['notifyWhenFull'] == true,
            );
          }
        } catch (e) {
          print('[Error] Error parsing preferences from followedDocs: $e');
        }
      }

      return Document(
        date: json['date'] is String ? json['date'] : '',
        time: timeStr,
        clubs: clubs,
        followed: isFollowed,
        notificationPreferences: preferences,
        selectedLocations: selectedLocations,
      );
    } catch (e) {
      print('[Error] Error in Document.fromJson: $e for JSON: $json');
      // Return a minimal valid document instead of throwing
      return Document(
        date: json['date'] is String ? json['date'] : '',
        time: json['time'] is String
            ? json['time'].substring(0, min<int>(5, json['time'].length))
            : '00:00',
        clubs: {},
        followed: false,
        selectedLocations: selectedLocations,
      );
    }
  }
}
