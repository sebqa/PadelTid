import 'package:flutter/material.dart';

class LocationSelect extends StatefulWidget {
  const LocationSelect({super.key});

  @override
  State<LocationSelect> createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  String? _selectedLocation;
  final List<String> _locations = ['Holbæk Padel Klub', 'Racket Club Roskilde', 'Mørkøv Padel Klub'];

  @override
  State<LocationSelect> createState() => _LocationSelectState();

  @override
  void initState() {
    super.initState();
    _selectedLocation = _locations[0];
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width/2,
      child: Row(
        children: [                    Icon(Icons.location_pin, color: Theme.of(context).colorScheme.onPrimary),
      
          ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<String>(
                      underline: Text(''),
            isDense: true,
              value: _selectedLocation,
              onChanged: (newValue) {
                setState(() {
                  _selectedLocation = newValue;
                });
              },
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  child: SizedBox(child: Text(location, style: TextStyle(fontSize: 12.0),overflow: TextOverflow.ellipsis,)),
                  value: location,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    
  }

}