import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Location {
  final String name;
  final String location;
  final String imageUrl;

  Location(
      {required this.name, required this.location, required this.imageUrl});
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
  List<Location> _selectedLocations = [];
  final List<Location> _availableLocations = [
    Location(
        name: 'Holbæk Padel Klub',
        location: '59.3293° N, 18.0686° E',
        imageUrl: 'https://example.com/stockholm.jpg'),
    Location(
        name: 'Mørkøv Padel Klub',
        location: '57.7089° N, 11.9746° E',
        imageUrl: 'https://example.com/gothenburg.jpg'),
    Location(
        name: 'Racket Club Roskilde',
        location: '55.6050° N, 13.0038° E',
        imageUrl: 'https://example.com/malmo.jpg'),
    // Add more locations as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLocations();
  }

  Future<void> _loadSelectedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocations = prefs.getStringList('selected_locations') ?? [];
    setState(() {
      _selectedLocations = _availableLocations
          .where((location) => savedLocations.contains(location.name))
          .toList();
    });
  }

  Future<void> _saveSelectedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'selected_locations', _selectedLocations.map((l) => l.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiSelectDialogField<Location>(
          items: _availableLocations
              .map((location) =>
                  MultiSelectItem<Location>(location, location.name))
              .toList(),
          initialValue: _selectedLocations,
          searchable: true,
          title: Text("Select Locations"),
          selectedColor: Theme.of(context).colorScheme.primary,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
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
              _selectedLocations = results;
            });
            widget.onLocationsChanged(
                _selectedLocations.map((l) => l.name).toList());
            _saveSelectedLocations();
          },
          chipDisplay: MultiSelectChipDisplay.none(),
        );
      },
    );
  }

  String _getButtonText(double maxWidth) {
    if (_selectedLocations.isEmpty) {
      return "Select locations";
    } else if (_selectedLocations.length == 1) {
      return _selectedLocations[0].name;
    } else {
      String text = _selectedLocations.map((l) => l.name).join(", ");
      int maxChars = (maxWidth / 10).floor(); // Adjusted calculation
      if (text.length > maxChars) {
        return "${text.substring(0, maxChars)}... (${_selectedLocations.length})";
      } else {
        return text;
      }
    }
  }
}
