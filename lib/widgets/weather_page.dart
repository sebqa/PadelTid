import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/widgets/wind_speed_indicator.dart';

class WeatherPage extends StatefulWidget {
  final Map<String, dynamic> weatherData;
  final Document document;

  WeatherPage({required this.weatherData, required this.document});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> cities = ['Holbæk'];
  List<String> filteredCities = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    filteredCities = cities;
  }

  void _filterCities(String query) {
    setState(() {
      filteredCities = cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
      isSearching = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentData =
        widget.weatherData['current']['data']['instant']['details'];
    final nextData = widget.weatherData['next']['data'];
    final next1HourData =
        widget.weatherData['next']['data'].containsKey('next_1_hours')
            ? widget.weatherData['next']['data']['next_1_hours']
            : widget.weatherData['next']['data']['next_6_hours'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a city',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterCities('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _filterCities,
              ),
            ),
            if (isSearching)
              Expanded(
                child: ListView.separated(
                  itemCount: filteredCities.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredCities[index]),
                      onTap: () {
                        setState(() {
                          _searchController.text = filteredCities[index];
                          isSearching = false;
                          _filterCities(_searchController.text);
                        });
                      },
                    );
                  },
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live data',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.wb_sunny, size: 40),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currentData['air_temperature']}° ${next1HourData['summary']['symbol_code']}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  'H: ${nextData['next_6_hours']['details']['air_temperature_max']}° - L: ${nextData['next_6_hours']['details']['air_temperature_min']}°',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Text('Wind',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 8),
                        WindSpeedIndicator(
                            windSpeed: currentData['wind_speed'].toDouble()),
                        SizedBox(height: 24),
                        Text('Next 2 hours',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 8),
                        _buildHourlyForecast(
                            widget.weatherData['current']['data']),
                        _buildHourlyForecast(
                            widget.weatherData['next']['data']),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> hourData) {
    return ListTile(
      leading: Icon(Icons.wb_sunny),
      title: Text(
        '${hourData['next_1_hours']['summary']['symbol_code']}, ${hourData['instant']['details']['air_temperature']}°',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
          'Precipitation: ${hourData['next_1_hours']['details']['precipitation_amount']} mm'),
    );
  }
}
