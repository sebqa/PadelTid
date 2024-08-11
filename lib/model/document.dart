class Document {
  final double airTemperature;
  final int? availableSlots;
  final String date;
  final double precipitationProbability;
  final String time;
  final double windSpeed;
  final String symbolCode;
  final bool? following;

  Document({
    required this.airTemperature,
    required this.availableSlots,
    required this.date,
    required this.precipitationProbability,
    required this.time,
    required this.windSpeed,
    required this.symbolCode,
    this.following,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      airTemperature: json['air_temperature'],
      availableSlots: json.containsKey('available_slots') ? json['available_slots'] : 0,
      following: json.containsKey('following') ? json['following'] : false,
      date: json['date'],
      //if precipitationProbability is 0 then set to 0.0
      //if not 0 then set to the original value
      
      precipitationProbability: json['precipitation_probability'],
      //strip the seconds from the time
      time: json['time'].substring(0, 5),
      windSpeed: json['wind_speed'],
      symbolCode: json['symbol_code'],

    );
  }
}
