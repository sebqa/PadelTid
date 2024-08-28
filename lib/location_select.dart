import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter_application_1/model/location.dart';
import 'package:flutter/rendering.dart';

final List<Location> _list = [
  Location(
      name: 'Holbæk Padel Klub', latitude: 52.370216, longitude: 12.739917),
  Location(
      name: 'Racket Club Roskilde', latitude: 52.370216, longitude: 12.739917),
  Location(
      name: 'Mørkøv Padel Klub', latitude: 52.370216, longitude: 12.739917),
];

Future<List<Location>> _getFakeRequestData(String query) async {
  return await Future.delayed(const Duration(seconds: 1), () {
    return _list.where((e) {
      return e.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  });
}

class MultiSelectSearchRequestDropdown extends StatelessWidget {
  const MultiSelectSearchRequestDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: 200,
        height: 50,
        child: CustomDropdown<Location>.multiSelectSearchRequest(
          initialItems: [_list[0]],
          futureRequest: _getFakeRequestData,
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Row(
              children: [
                Checkbox(value: isSelected, onChanged: null),
                Text(
                  item.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          },
          onListChanged: (value) {
            print(
                'MultiSelectSearchRequestDropdown onListChanged value: $value');
          },
        ),
      ),
    );
  }
}
