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
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' show TextDirection;
import 'dart:math' as math;
import 'package:flutter_application_1/document_service.dart';

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

class _DocumentDetailsPageState extends State<DocumentDetailsPage>
    with SingleTickerProviderStateMixin {
  // Map to store weather forecasts for each club
  Map<String, List<DetailedWeather>> _clubWeatherForecasts = {};
  Map<String, bool> _clubLoadingStates = {};
  Map<String, String> _clubErrorMessages = {};
  // Track expanded state for each club
  Map<String, bool> _expandedClubs = {};

  // Document state
  bool _isLoading = true;
  String? _errorMessage;
  Document? _document;

  // Animation controller for shimmer effect
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: Duration(milliseconds: 1000));

    _loadDocument();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    if (widget.document != null) {
      // If document is provided directly, use it
      setState(() {
        _document = widget.document;
        _isLoading = false;
      });
      _initializeClubWeatherStates();
    } else if (widget.documentId != null) {
      // If only ID is provided, fetch the document
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final document =
            await DocumentService().getDocumentById(widget.documentId!);

        if (mounted) {
          setState(() {
            _document = document;
            _isLoading = false;
          });
          _initializeClubWeatherStates();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load document: $e';
            _isLoading = false;
          });
        }
        print('Error loading document: $e');
      }
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
                  .isAfter(docDateTime.subtract(Duration(hours: 0))) &&
              forecastTime.isBefore(docDateTime.add(Duration(hours: 5)));
        }).toList();

        // Sort by time to ensure correct order
        forecastTimes.sort((a, b) =>
            DateTime.parse(a['time']).compareTo(DateTime.parse(b['time'])));

        // Convert to DetailedWeather objects
        final forecasts = forecastTimes
            .map((item) => DetailedWeather.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            _clubWeatherForecasts[clubName] = forecasts;
            _clubLoadingStates[clubName] = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _clubLoadingStates[clubName] = false;
            _clubErrorMessages[clubName] =
                'Failed to fetch weather data: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clubLoadingStates[clubName] = false;
          _clubErrorMessages[clubName] = 'Error fetching weather data: $e';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_document == null) {
      // If we don't have a document yet, try to load it
      return _loadDocument();
    }

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

  String _formatDate(String dateStr, BuildContext context) {
    final date = DateTime.parse(dateStr);
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? Text(
                TranslationHelper.translate(
                    'loading', localeProvider.locale.languageCode),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              )
            : Text(
                _document != null
                    ? '${_formatDate(_document!.date, context)} ${TranslationHelper.translate('at', localeProvider.locale.languageCode)} ${_document!.time}'
                    : TranslationHelper.translate(
                        'available_courts', localeProvider.locale.languageCode),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 1, // Subtle elevation
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary, // Back button color
        ),
      ),
      body: _isLoading
          ? _buildLoadingUI(context)
          : _errorMessage != null
              ? _buildErrorUI(context)
              : _buildDocumentUI(context),
    );
  }

  Widget _buildLoadingUI(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club skeletons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children:
                    List.generate(3, (index) => _buildClubSkeleton(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubSkeleton(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Club header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Club logo placeholder
                _buildShimmerPlaceholder(
                    height: 40, width: 40, shape: BoxShape.circle),
                SizedBox(width: 12),

                // Club name and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerPlaceholder(height: 18, width: 160),
                      SizedBox(height: 4),
                      _buildShimmerPlaceholder(height: 14, width: 120),
                    ],
                  ),
                ),

                // Availability indicator placeholder
                _buildShimmerPlaceholder(
                    height: 32, width: 80, borderRadius: 16),
              ],
            ),
          ),

          // Basic weather information placeholder
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerPlaceholder(
                height: 80, width: double.infinity, borderRadius: 12),
          ),

          SizedBox(height: 16),

          // Weather forecast button (collapsed state only)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerPlaceholder(
                height: 40, width: double.infinity, borderRadius: 8),
          ),

          SizedBox(height: 16),

          // Book court button placeholder
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: _buildShimmerPlaceholder(
                  height: 48, width: 200, borderRadius: 8),
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder(
      {required double height,
      required double width,
      double borderRadius = 4,
      BoxShape shape = BoxShape.rectangle}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(borderRadius)
                : null,
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                  slidePercent: _shimmerController.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDocument,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUI(BuildContext context) {
    // Show document details
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: EdgeInsets.only(top: 16, bottom: 24),
        children: [
          // Club sections
          if (_document!.clubs.isNotEmpty)
            ..._document!.clubs.entries.map((clubEntry) {
              return _buildClubSection(
                context,
                clubEntry.key,
                clubEntry.value,
              );
            }).toList(),
        ],
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
      margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
}

// Helper class for shimmer animation
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
