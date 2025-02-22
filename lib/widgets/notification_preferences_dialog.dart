import 'package:flutter/material.dart';

class NotificationPreferences {
  bool notifyOnWeatherChange;
  bool notifyWhenAvailable;
  bool notifyWhenOneLeft;
  bool notifyWhenFull;

  NotificationPreferences({
    this.notifyOnWeatherChange = true,
    this.notifyWhenAvailable = true,
    this.notifyWhenOneLeft = false,
    this.notifyWhenFull = false,
  });

  Map<String, dynamic> toJson() => {
    'notifyOnWeatherChange': notifyOnWeatherChange,
    'notifyWhenAvailable': notifyWhenAvailable,
    'notifyWhenOneLeft': notifyWhenOneLeft,
    'notifyWhenFull': notifyWhenFull,
  };
}

class NotificationPreferencesDialog extends StatefulWidget {
  final NotificationPreferences initialPreferences;
  final Function(NotificationPreferences) onSave;

  const NotificationPreferencesDialog({
    Key? key,
    required this.initialPreferences,
    required this.onSave,
  }) : super(key: key);

  @override
  State<NotificationPreferencesDialog> createState() => _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState extends State<NotificationPreferencesDialog> {
  late NotificationPreferences preferences;

  @override
  void initState() {
    super.initState();
    preferences = NotificationPreferences(
      notifyOnWeatherChange: widget.initialPreferences.notifyOnWeatherChange,
      notifyWhenAvailable: widget.initialPreferences.notifyWhenAvailable,
      notifyWhenOneLeft: widget.initialPreferences.notifyWhenOneLeft,
      notifyWhenFull: widget.initialPreferences.notifyWhenFull,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Preferences'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Weather changes'),
            subtitle: const Text('Notify when weather conditions change significantly'),
            value: preferences.notifyOnWeatherChange,
            onChanged: (bool? value) {
              setState(() {
                preferences.notifyOnWeatherChange = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Courts become available'),
            subtitle: const Text('Notify when courts become available'),
            value: preferences.notifyWhenAvailable,
            onChanged: (bool? value) {
              setState(() {
                preferences.notifyWhenAvailable = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('One court left'),
            subtitle: const Text('Notify when only one court remains'),
            value: preferences.notifyWhenOneLeft,
            onChanged: (bool? value) {
              setState(() {
                preferences.notifyWhenOneLeft = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Courts full'),
            subtitle: const Text('Notify when all courts are booked'),
            value: preferences.notifyWhenFull,
            onChanged: (bool? value) {
              setState(() {
                preferences.notifyWhenFull = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(preferences);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 