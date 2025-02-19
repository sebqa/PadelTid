class ClubAvailability {
  final String clubId;
  final String clubName;
  final int availableSlots;
  final int totalCourts;
  final Weather weather;

  ClubAvailability({
    required this.clubId,
    required this.clubName,
    required this.availableSlots,
    required this.totalCourts,
    required this.weather,
  });

  factory ClubAvailability.fromJson(Map<String, dynamic> json) {
    return ClubAvailability(
      clubId: json['club_id'],
      clubName: json['club_name'],
      availableSlots: json['available_slots'],
      totalCourts: json['total_courts'],
      weather: Weather.fromJson(json['weather']),
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
  final bool? subscribed;
  final List<String> selectedLocations;

  Document({
    required this.date,
    required this.time,
    required this.clubs,
    required this.selectedLocations,
    this.subscribed,
  });

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
  double get precipitationProbability => weather?.precipitationProbability ?? 0.0;
  double get windSpeed => weather?.windSpeed ?? 0.0;
  String get symbolCode => weather?.symbolCode ?? 'clearsky_day';

  int get totalAvailableSlots => 
    clubs.values.fold(0, (sum, club) => sum + club.availableSlots);

  int get totalClubs => selectedLocations.isEmpty 
    ? clubs.length 
    : clubs.keys.where((club) => selectedLocations.contains(club)).length;

  factory Document.fromJson(Map<String, dynamic> json, List<dynamic> subscribedDocs, {List<String> selectedLocations = const []}) {
    Map<String, ClubAvailability> clubs = {};
    if (json.containsKey('clubs')) {
      (json['clubs'] as Map<String, dynamic>).forEach((key, value) {
        if (value != null) {  // Only add non-null club data
          clubs[key] = ClubAvailability.fromJson(value);
        }
      });
    }

    return Document(
      date: json['date'],
      time: json['time'].substring(0, 5),
      clubs: clubs,
      subscribed: subscribedDocs.contains(json['date'].replaceAll('-', '') + json['time'].replaceAll(':', '')) ? true : false,
      selectedLocations: selectedLocations,
    );
  }

  set subscribed(bool? value) {
    subscribed = value;
  }
}
