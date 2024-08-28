import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class LocationSelector extends StatefulWidget {
  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  List<Location> _selectedLocations = [];
  final List<Location> _locations = [
    Location(
        name: 'Holbæk Padel Klub',
        location: '59.3293° N, 18.0686° E',
        imageUrl: 'https://example.com/stockholm.jpg'),
    Location(
        name: 'Mørkehøj Padel Klub',
        location: '57.7089° N, 11.9746° E',
        imageUrl: 'https://example.com/gothenburg.jpg'),
    Location(
        name: 'Racket Club Roskile',
        location: '55.6050° N, 13.0038° E',
        imageUrl: 'https://example.com/malmo.jpg'),
    // Add more locations as needed
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return MultiSelectDialogField<Location>(
          items: _locations
              .map((e) => MultiSelectItem<Location>(e, e.name))
              .toList(),
          listType: MultiSelectListType.LIST,
          onConfirm: (values) {
            setState(() {
              _selectedLocations = values;
            });
          },
          chipDisplay: MultiSelectChipDisplay.none(),
          title: Text("Select locations"),
          selectedColor: Theme.of(context).colorScheme.primary,
          buttonIcon: Icon(Icons.location_on,
              color: Theme.of(context).colorScheme.onSurface),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          buttonText: Text(
            _getButtonText(constraints.maxWidth),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.normal),
          ),
          searchable: true,
          selectedItemsTextStyle: TextStyle(color: Colors.black),
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
