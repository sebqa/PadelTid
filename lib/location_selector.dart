import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Club {
  final String id;
  final String name;
  final String url;
  final int totalCourts;

  Club({
    required this.id,
    required this.name,
    required this.url,
    required this.totalCourts,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['_id'],
      name: json['name'],
      url: json['url'],
      totalCourts: json['total_courts'],
    );
  }
}

class LocationSelector extends StatefulWidget {
  final Function(List<String>) onLocationsChanged;
  final List<String> initialLocations;

  LocationSelector({
    required this.onLocationsChanged,
    required this.initialLocations,
  });

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late List<String> selectedLocations;
  List<Location> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedLocations = List.from(widget.initialLocations);
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getClubs'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          locations = data.map((item) => Location(
            name: item['name'],
            latitude: item['latitude'],
            longitude: item['longitude'],
          )).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: locations.map((location) {
          final isSelected = selectedLocations.contains(location.name);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedLocations.remove(location.name);
                  } else {
                    selectedLocations.add(location.name);
                  }
                });
                widget.onLocationsChanged(selectedLocations);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white54,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  location.name,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
