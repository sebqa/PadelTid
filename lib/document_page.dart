import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/widgets/weather_page.dart';

class DocumentPage extends StatefulWidget {
  final Document document;

  DocumentPage({required this.document});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=55.697596&lon=11.68873'));
      if (response.statusCode == 200) {
        final timeseries =
            json.decode(response.body)!['properties']['timeseries'];
        for (int i = 0; i < timeseries.length - 1; i++) {
          if (timeseries[i]['time'] ==
              widget.document.date + 'T' + widget.document.time + ':00Z') {
            setState(() {
              weatherData = {
                'current': timeseries[i],
                'next': timeseries[i + 1]
              };
              isLoading = false;
            });
            return;
          }
        }
        // If no matching time is found
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.document.date} at ${widget.document.time}',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : weatherData != null
              ? WeatherPage(
                  weatherData: weatherData!, document: widget.document)
              : Center(child: Text('Failed to load weather data')),
    );
  }
}
