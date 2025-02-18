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

  const LocationSelector({
    Key? key,
    required this.onLocationsChanged,
    required this.initialLocations,
  }) : super(key: key);

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  List<Club> _selectedClubs = [];
  List<Club> _availableClubs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('https://rvhxwa55v5.execute-api.eu-north-1.amazonaws.com/default/getClubs'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> clubsJson = json.decode(response.body);
        final clubs = clubsJson.map((json) => Club.fromJson(json)).toList();
        
        final prefs = await SharedPreferences.getInstance();
        final savedLocations = prefs.getStringList('selected_locations') ?? [];

        setState(() {
          _availableClubs = clubs;
          _selectedClubs = _availableClubs
              .where((club) => savedLocations.contains(club.name))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load clubs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'selected_locations', _selectedClubs.map((c) => c.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiSelectDialogField<Club>(
          items: _availableClubs
              .map((club) => MultiSelectItem<Club>(club, club.name))
              .toList(),
          initialValue: _selectedClubs,
          searchable: true,
          title: Text("Select Locations"),
          selectedColor: Theme.of(context).colorScheme.primary,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.all(Radius.circular(40)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primaryContainer,
              width: 2,
            ),
          ),
          buttonIcon: Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          buttonText: Text(
            _getButtonText(constraints.maxWidth),
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal),
          ),
          onConfirm: (results) {
            setState(() {
              _selectedClubs = results;
            });
            widget.onLocationsChanged(
                _selectedClubs.map((c) => c.name).toList());
            _saveSelectedLocations();
          },
          chipDisplay: MultiSelectChipDisplay.none(),
        );
      },
    );
  }

  String _getButtonText(double maxWidth) {
    if (_selectedClubs.isEmpty) {
      return "Select locations";
    } else if (_selectedClubs.length == 1) {
      return _selectedClubs[0].name;
    } else {
      String text = _selectedClubs.map((c) => c.name).join(", ");
      int maxChars = (maxWidth / 10).floor();
      if (text.length > maxChars) {
        return "${text.substring(0, maxChars)}... (${_selectedClubs.length})";
      } else {
        return text;
      }
    }
  }
}
