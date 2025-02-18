class ClubAvailability {
  final String clubId;
  final String clubName;
  final int availableSlots;
  final int totalCourts;

  ClubAvailability({
    required this.clubId,
    required this.clubName,
    required this.availableSlots,
    required this.totalCourts,
  });

  factory ClubAvailability.fromJson(Map<String, dynamic> json) {
    return ClubAvailability(
      clubId: json['club_id'],
      clubName: json['club_name'],
      availableSlots: json['available_slots'],
      totalCourts: json['total_courts'],
    );
  }
}

class Document {
  final double airTemperature;
  final Map<String, ClubAvailability> clubs;
  final String date;
  final double precipitationProbability;
  final String time;
  final double windSpeed;
  final String symbolCode;
  final bool? subscribed;

  Document({
    required this.airTemperature,
    required this.clubs,
    required this.date,
    required this.precipitationProbability,
    required this.time,
    required this.windSpeed,
    required this.symbolCode,
    this.subscribed,
  });

  int get totalAvailableSlots => 
    clubs.values.fold(0, (sum, club) => sum + club.availableSlots);

  int get totalClubs => clubs.length;

  factory Document.fromJson(Map<String, dynamic> json, List<dynamic> subscribedDocs) {
    Map<String, ClubAvailability> clubs = {};
    if (json.containsKey('clubs')) {
      (json['clubs'] as Map<String, dynamic>).forEach((key, value) {
        clubs[key] = ClubAvailability.fromJson(value);
      });
    }

    return Document(
      airTemperature: json['air_temperature'],
      clubs: clubs,
      subscribed: subscribedDocs.contains(json['date'].replaceAll('-', '') + json['time'].replaceAll(':', '')) ? true : false,
      date: json['date'],
      precipitationProbability: json['precipitation_probability'],
      time: json['time'].substring(0, 5),
      windSpeed: json['wind_speed'],
      symbolCode: json['symbol_code'],
    );
  }

  set subscribed(bool? value) {
    subscribed = value;
  }
}
