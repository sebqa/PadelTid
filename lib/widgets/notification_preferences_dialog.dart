import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widgets/subscription_dialogs.dart';

class NotificationPreferences {
  bool notifyOnWeatherChange;
  bool notifyWhenAvailable;
  bool notifyWhenOneLeft;
  bool notifyWhenFull;

  NotificationPreferences({
    this.notifyOnWeatherChange = true,
    this.notifyWhenAvailable = false,
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
  State<NotificationPreferencesDialog> createState() =>
      _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState
    extends State<NotificationPreferencesDialog> {
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
      contentPadding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
      content: FutureBuilder<bool>(
        future: SubscriptionService.isSubscribed,
        builder: (context, snapshot) {
          final isSubscribed = snapshot.data ?? false;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.wb_cloudy),
                  title: const Text('Weather changes'),
                  subtitle: const Text('Notify when weather conditions change'),
                  trailing: Switch(
                    value: preferences.notifyOnWeatherChange,
                    onChanged: (bool? value) {
                      setState(() {
                        preferences.notifyOnWeatherChange = value ?? false;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.looks_one),
                  title: const Text('One court left'),
                  subtitle: const Text('Notify when only one court remains'),
                  trailing: Switch(
                    value: preferences.notifyWhenOneLeft,
                    onChanged: (bool? value) {
                      setState(() {
                        preferences.notifyWhenOneLeft = value ?? false;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Courts full'),
                  subtitle: const Text('Notify when all courts are booked'),
                  trailing: Switch(
                    value: preferences.notifyWhenFull,
                    onChanged: (bool? value) {
                      setState(() {
                        preferences.notifyWhenFull = value ?? false;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: !isSubscribed
                      ? Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.notifications_active),
                  title: const Text('Courts become available'),
                  subtitle: Row(
                    children: [
                      const Flexible(
                        child: Text('Notify when courts become available'),
                      ),
                      if (!isSubscribed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Switch(
                    value:
                        isSubscribed ? preferences.notifyWhenAvailable : false,
                    onChanged: isSubscribed
                        ? (bool? value) {
                            setState(() {
                              preferences.notifyWhenAvailable = value ?? false;
                            });
                          }
                        : (_) => SubscriptionDialogs.showSubscriptionDialog(
                              context,
                              () => setState(() {}),
                            ),
                  ),
                ),
              ],
            ),
          );
        },
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
