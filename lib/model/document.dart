import 'package:flutter_application_1/widgets/notification_preferences_dialog.dart';

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
    return ClubAvailability(
      clubId: json['club_id'],
      clubName: json['club_name'],
      clubUrl: json['club_url'] ?? '',
      availableSlots: json['available_slots'],
      totalCourts: json['total_courts'],
      weather: Weather.fromJson(json['weather']),
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
    );
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
    return Weather(
      windSpeed: json['wind_speed'].toDouble(),
      precipitationProbability: json['precipitation_probability'].toDouble(),
      airTemperature: json['air_temperature'].toDouble(),
      symbolCode: json['symbol_code'],
    );
  }
}

class Document {
  final String date;
  final String time;
  final Map<String, ClubAvailability> clubs;
  bool? _subscribed;
  NotificationPreferences? notificationPreferences;
  final List<String> selectedLocations;

  Document({
    required this.date,
    required this.time,
    required this.clubs,
    required this.selectedLocations,
    bool? subscribed,
    this.notificationPreferences,
  }) : _subscribed = subscribed;

  bool? get subscribed => _subscribed;
  set subscribed(bool? value) => _subscribed = value;

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
      Map<String, dynamic> json, List<dynamic> subscribedDocs,
      {List<String> selectedLocations = const []}) {
    Map<String, ClubAvailability> clubs = {};
    if (json.containsKey('clubs')) {
      (json['clubs'] as Map<String, dynamic>).forEach((key, value) {
        if (value != null) {
          clubs[key] = ClubAvailability.fromJson(value);
        }
      });
    }

    // Create document ID in the format YYYYMMDDHHMMSS
    final docId = json['date'].replaceAll('-', '') +
        json['time'].substring(0, 5).replaceAll(':', '') +
        "00";

    // Find subscription data for this document
    final subscriptionData = subscribedDocs.firstWhere(
      (sub) => sub['id'] == docId,
      orElse: () => null,
    );

    // Get preferences from subscription data if it exists
    NotificationPreferences? preferences;
    if (subscriptionData != null && subscriptionData['preferences'] != null) {
      final prefsJson = subscriptionData['preferences'] as Map<String, dynamic>;
      preferences = NotificationPreferences(
        notifyOnWeatherChange: prefsJson['notifyOnWeatherChange'] ?? true,
        notifyWhenAvailable: prefsJson['notifyWhenAvailable'] ?? true,
        notifyWhenOneLeft: prefsJson['notifyWhenOneLeft'] ?? false,
        notifyWhenFull: prefsJson['notifyWhenFull'] ?? false,
      );
    }

    return Document(
      date: json['date'],
      time: json['time'].substring(0, 5),
      clubs: clubs,
      subscribed: subscriptionData != null,
      notificationPreferences: preferences,
      selectedLocations: selectedLocations,
    );
  }
}
