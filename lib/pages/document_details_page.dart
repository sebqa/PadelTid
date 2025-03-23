import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/document.dart';
import '../model/detailed_weather.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DocumentDetailsPage extends StatefulWidget {
  final Document? document;
  final String? documentId;

  // Allow creating with either a document or a document ID
  const DocumentDetailsPage({Key? key, this.document, this.documentId})
      : assert(document != null || documentId != null),
        super(key: key);

  @override
  _DocumentDetailsPageState createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  // Map to store weather forecasts for each club
  Map<String, List<DetailedWeather>> _clubWeatherForecasts = {};
  Map<String, bool> _clubLoadingStates = {};
  Map<String, String> _clubErrorMessages = {};
  // Track expanded state for each club
  Map<String, bool> _expandedClubs = {};

  // Add a future for loading document by ID
  Future<Document>? _documentFuture;
  Document? _document;

  @override
  void initState() {
    super.initState();

    if (widget.document != null) {
      // If document is provided directly, use it
      _document = widget.document;
      _initializeClubWeatherStates();
    } else if (widget.documentId != null) {
      // If only ID is provided, fetch the document
      _documentFuture = _fetchDocumentById(widget.documentId!);
      _documentFuture!.then((document) {
        setState(() {
          _document = document;
          _initializeClubWeatherStates();
        });
      });
    }
  }

  Future<Document> _fetchDocumentById(String documentId) async {
    try {
      // Use the Lambda Function URL instead of API Gateway
      final response = await http.get(
        Uri.parse(
            'https://laseojfvjff4ms5nagckrhrd2u0cprtj.lambda-url.eu-north-1.on.aws/?documentId=$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Document.fromJson(data, []);
      } else {
        throw Exception('Failed to load document: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching document: $e');
      throw Exception('Failed to load document: $e');
    }
  }

  void _initializeClubWeatherStates() {
    if (_document == null) return;

    for (var clubEntry in _document!.clubs.entries) {
      if (clubEntry.value.latitude.isNotEmpty &&
          clubEntry.value.longitude.isNotEmpty) {
        _clubLoadingStates[clubEntry.key] = true;
        _expandedClubs[clubEntry.key] = false; // Start collapsed
        _fetchDetailedWeatherForClub(clubEntry.key, clubEntry.value);
      }
    }
  }

  Future<void> _fetchDetailedWeatherForClub(
      String clubName, ClubAvailability club) async {
    if (club.latitude.isEmpty || club.longitude.isEmpty) {
      setState(() {
        _clubLoadingStates[clubName] = false;
        _clubErrorMessages[clubName] = 'Location data not available';
      });
      return;
    }

    try {
      final url = Uri.parse(
          'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=${club.latitude}&lon=${club.longitude}');

      final response = await http.get(url,
          headers: {'User-Agent': 'PadelTid/1.0 (contact@padeltid.com)'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timeseries = data['properties']['timeseries'] as List;

        // Parse document date and time
        final docDateTime =
            DateTime.parse('${_document!.date}T${_document!.time}');

        // Find closest forecast times (hour before, current hour, next two hours)
        final forecastTimes = timeseries.where((item) {
          final forecastTime = DateTime.parse(item['time']);
          // Filter to get -1h, 0h, +1h, +2h relative to document time
          return forecastTime
                  .isAfter(docDateTime.subtract(Duration(hours: 1))) &&
              forecastTime.isBefore(docDateTime.add(Duration(hours: 4)));
        }).toList();

        // Sort by time to ensure correct order
        forecastTimes.sort((a, b) =>
            DateTime.parse(a['time']).compareTo(DateTime.parse(b['time'])));

        // Convert to DetailedWeather objects
        final forecasts = forecastTimes
            .map((item) => DetailedWeather.fromJson(item))
            .toList();

        setState(() {
          _clubWeatherForecasts[clubName] = forecasts;
          _clubLoadingStates[clubName] = false;
        });
      } else {
        setState(() {
          _clubLoadingStates[clubName] = false;
          _clubErrorMessages[clubName] =
              'Failed to fetch weather data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _clubLoadingStates[clubName] = false;
        _clubErrorMessages[clubName] = 'Error fetching weather data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      // Reset loading states and error messages
      _clubLoadingStates.clear();
      _clubErrorMessages.clear();
    });

    // Re-initialize and fetch weather data for all clubs
    for (var clubEntry in _document!.clubs.entries) {
      if (clubEntry.value.latitude.isNotEmpty &&
          clubEntry.value.longitude.isNotEmpty) {
        setState(() {
          _clubLoadingStates[clubEntry.key] = true;
        });
        await _fetchDetailedWeatherForClub(clubEntry.key, clubEntry.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're loading the document, show a loading indicator
    if (widget.document == null && _document == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Use the loaded document
    final document = _document ?? widget.document!;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_formatDate(document.date, context)} ${TranslationHelper.translate('at', languageCode)} ${document.time}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: EdgeInsets.only(top: 8, bottom: 24),
          children: [
            // Club sections
            if (document.clubs.isNotEmpty)
              ...document.clubs.entries.map((clubEntry) {
                return _buildClubSection(
                  context,
                  clubEntry.key,
                  clubEntry.value,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClubSection(
      BuildContext context, String clubName, ClubAvailability club) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;
    final hasDetailedWeather =
        club.latitude.isNotEmpty && club.longitude.isNotEmpty;
    final isExpanded = _expandedClubs[clubName] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        clubName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${club.availableSlots}/${club.totalCourts} ${TranslationHelper.translate('courts', languageCode)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Basic weather information
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherInfo(
                        context,
                        Icons.thermostat,
                        '${club.weather.airTemperature}${TranslationHelper.translate('temperature_unit', languageCode)}',
                        TranslationHelper.translate(
                            'temperature', languageCode),
                      ),
                      _buildWeatherInfo(
                        context,
                        Icons.air,
                        '${club.weather.windSpeed}${TranslationHelper.translate('meters_per_second', languageCode)}',
                        TranslationHelper.translate('wind_speed', languageCode),
                      ),
                      _buildWeatherInfo(
                        context,
                        Icons.umbrella,
                        '${club.weather.precipitationProbability}${TranslationHelper.translate('percent', languageCode)}',
                        TranslationHelper.translate(
                            'precipitation', languageCode),
                      ),
                    ],
                  ),
                ),

                // Detailed weather forecast if available
                if (hasDetailedWeather) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Expandable header
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedClubs[clubName] = !isExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                TranslationHelper.translate(
                                    'detailed_weather', languageCode),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),

                        // Only show details if expanded
                        if (isExpanded) ...[
                          SizedBox(height: 16),
                          if (_clubLoadingStates[clubName] == true)
                            Center(
                                child: SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            ))
                          else if (_clubErrorMessages.containsKey(clubName))
                            Center(child: Text(_clubErrorMessages[clubName]!))
                          else if (_clubWeatherForecasts[clubName]?.isEmpty ??
                              true)
                            Center(
                                child: Text(TranslationHelper.translate(
                                    'no_forecast', languageCode)))
                          else
                            _buildWeatherForClub(
                                context, _clubWeatherForecasts[clubName]!),
                        ],
                      ],
                    ),
                  ),
                ],

                // Book Court button - moved below weather details
                if (club.clubUrl.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.sports_tennis),
                      label: Text(TranslationHelper.translate(
                          'book_court', languageCode)),
                      onPressed: () async {
                        final url = Uri.parse(club.clubUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherForClub(
      BuildContext context, List<DetailedWeather> forecasts) {
    final languageCode =
        Provider.of<LocaleProvider>(context).locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather time slots
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            TranslationHelper.translate('hourly_forecast', languageCode),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Horizontal scrollable cards
        Container(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecasts.length,
            separatorBuilder: (context, index) => SizedBox(width: 8),
            itemBuilder: (context, index) {
              final weather = forecasts[index];
              return _buildWeatherTimeCard(context, weather);
            },
          ),
        ),

        // Additional details for first forecast
        if (forecasts.isNotEmpty) ...[
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              TranslationHelper.translate('weather_details', languageCode),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _buildWeatherMetrics(context, forecasts.first, languageCode),
          SizedBox(height: 16),
          _buildPadelConditions(context, forecasts.first, languageCode),
        ],
      ],
    );
  }

  Widget _buildWeatherTimeCard(BuildContext context, DetailedWeather weather) {
    return Container(
      width: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            DateFormat('HH:mm').format(weather.time),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Divider(height: 8, thickness: 0.5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thermostat, size: 14),
              SizedBox(width: 2),
              Text('${weather.airTemperature.toStringAsFixed(1)}°C',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, size: 14),
              SizedBox(width: 2),
              Text('${weather.windSpeed.toStringAsFixed(1)} m/s',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.umbrella, size: 14),
              SizedBox(width: 2),
              Text('${weather.precipitationProbability.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetrics(
      BuildContext context, DetailedWeather weather, String languageCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDetailedWeatherInfoItem(
          context,
          Icons.compress,
          '${weather.airPressure.round()} hPa',
          TranslationHelper.translate('air_pressure', languageCode),
        ),
        _buildDetailedWeatherInfoItem(
          context,
          Icons.opacity,
          '${weather.humidity.round()}${TranslationHelper.translate('percent', languageCode)}',
          TranslationHelper.translate('humidity', languageCode),
        ),
        _buildDetailedWeatherInfoItem(
          context,
          Icons.navigation,
          '${weather.windDirection.round()}°',
          TranslationHelper.translate('wind_direction', languageCode),
        ),
      ],
    );
  }

  Widget _buildPadelConditions(
      BuildContext context, DetailedWeather weather, String languageCode) {
    final behavior = weather.padelBallBehavior;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('padel_conditions', languageCode),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBallBehaviorItem(
                context,
                Icons.speed,
                TranslationHelper.translate('speed', languageCode),
                TranslationHelper.translate(
                    behavior.getSpeedDescription(), languageCode),
                behavior.ballSpeed.round(),
              ),
              _buildBallBehaviorItem(
                context,
                Icons.height,
                TranslationHelper.translate('bounce', languageCode),
                TranslationHelper.translate(
                    behavior.getBounceDescription(), languageCode),
                behavior.ballBounce.round(),
              ),
              _buildBallBehaviorItem(
                context,
                Icons.social_distance,
                TranslationHelper.translate('control', languageCode),
                TranslationHelper.translate(
                    behavior.getControlDescription(), languageCode),
                behavior.ballControl.round(),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Restored recommendations section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ball recommendation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_baseball,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          TranslationHelper.translate(
                              'recommended_ball', languageCode),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 24, top: 4),
                      child: Text(
                        TranslationHelper.translate(
                            behavior.recommendedBallType, languageCode),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Strategy tips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          TranslationHelper.translate(
                              'strategy_tips', languageCode),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 24, top: 4),
                      child: Text(
                        TranslationHelper.translate(
                            behavior.playingStrategy, languageCode),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedWeatherInfoItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBallBehaviorItem(BuildContext context, IconData icon,
      String label, String description, int value) {
    Color getValueColor() {
      if (value < 90) return Colors.red;
      if (value < 95) return Colors.orange;
      if (value > 105) return Colors.green;
      if (value > 110) return Colors.blue;
      return Colors.grey.shade700;
    }

    return Column(
      children: [
        Icon(icon, size: 18),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: getValueColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            description,
            style: TextStyle(
              color: getValueColor(),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String date, BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    final documentDate = DateTime.parse(date);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (documentDate.year == now.year &&
        documentDate.month == now.month &&
        documentDate.day == now.day) {
      return TranslationHelper.translate('today', languageCode);
    } else if (documentDate.year == tomorrow.year &&
        documentDate.month == tomorrow.month &&
        documentDate.day == tomorrow.day) {
      return TranslationHelper.translate('tomorrow', languageCode);
    } else {
      final weekday = TranslationHelper.translate(
          [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday'
          ][documentDate.weekday - 1],
          languageCode);

      final month = TranslationHelper.translate(
          [
            'jan',
            'feb',
            'mar',
            'apr',
            'may',
            'jun',
            'jul',
            'aug',
            'sep',
            'oct',
            'nov',
            'dec'
          ][documentDate.month - 1],
          languageCode);

      return '$weekday, $month ${documentDate.day}';
    }
  }
}
