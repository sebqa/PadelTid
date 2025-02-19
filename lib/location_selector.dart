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

class Location {
  final String name;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
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

class _LocationSelectorState extends State<LocationSelector> with SingleTickerProviderStateMixin {
  late List<String> selectedLocations;
  List<Location> locations = [];
  bool isLoading = true;
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    selectedLocations = List.from(widget.initialLocations);
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
            latitude: item['latitude'].toDouble(),
            longitude: item['longitude'].toDouble(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with selected locations count
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
              if (isExpanded) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  selectedLocations.isEmpty 
                      ? 'Select locations' 
                      : '${selectedLocations.length} location${selectedLocations.length != 1 ? 's' : ''} selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                AnimatedRotation(
                  duration: Duration(milliseconds: 200),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        // Expandable location list
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: EdgeInsets.only(top: 8),
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: locations.map<Widget>((location) {
                      final isSelected = selectedLocations.contains(location.name);
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        child: Material(
                          color: Colors.transparent,
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
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF4A90E2) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Color(0xFF4A90E2) : Colors.white30,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                location.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
