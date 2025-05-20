import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widgets/subscription_dialogs.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:provider/provider.dart';

class NotificationPreferences {
  bool notifyOnWeatherChange;
  bool notifyWhenAvailable;
  bool notifyWhenOneLeft;
  bool notifyWhenFull;

  NotificationPreferences({
    this.notifyOnWeatherChange = false,
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
  final bool isSubscribed;

  const NotificationPreferencesDialog({
    Key? key,
    required this.initialPreferences,
    required this.onSave,
    required this.isSubscribed,
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationHelper.translate('notification_preferences',
                          localeProvider.locale.languageCode) ??
                      'Notification Preferences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather changes notification
                  _buildNotificationOption(
                    icon: Icons.wb_cloudy,
                    title: 'Weather changes',
                    subtitle: 'Notify when weather conditions change',
                    value: preferences.notifyOnWeatherChange,
                    onChanged: (value) {
                      setState(() {
                        preferences.notifyOnWeatherChange = value ?? false;
                      });
                    },
                  ),
                  const Divider(height: 1),

                  // One court left notification
                  _buildNotificationOption(
                    icon: Icons.looks_one,
                    title: 'One court left',
                    subtitle: 'Notify when only one court remains',
                    value: preferences.notifyWhenOneLeft,
                    onChanged: (value) {
                      setState(() {
                        preferences.notifyWhenOneLeft = value ?? false;
                      });
                    },
                  ),
                  const Divider(height: 1),

                  // Courts full notification
                  _buildNotificationOption(
                    icon: Icons.block,
                    title: 'Courts full',
                    subtitle: 'Notify when all courts are booked',
                    value: preferences.notifyWhenFull,
                    onChanged: (value) {
                      setState(() {
                        preferences.notifyWhenFull = value ?? false;
                      });
                    },
                  ),
                  const Divider(height: 1),

                  // Courts available notification
                  _buildNotificationOption(
                    icon: Icons.notifications_active,
                    title: 'Courts become available',
                    subtitle: 'Notify when courts become available',
                    value: preferences.notifyWhenAvailable,
                    onChanged: (value) {
                      setState(() {
                        preferences.notifyWhenAvailable = value ?? false;
                      });
                    },
                  ),

                  // Add padding at the bottom to account for the sticky buttons
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Sticky buttons at the bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(TranslationHelper.translate(
                          'cancel', localeProvider.locale.languageCode) ??
                      'Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(preferences);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(TranslationHelper.translate(
                          'save', localeProvider.locale.languageCode) ??
                      'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
