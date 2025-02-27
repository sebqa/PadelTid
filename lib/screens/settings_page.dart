import 'package:flutter/material.dart';
import '../widgets/language_selector.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('app_title'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Settings sections
            Card(
              child: Column(
                children: [
                  // Add your existing settings here

                  // Language selection in its own card
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            localizations.translate('select_language'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const Divider(),
                        const LanguageSelector(),
                      ],
                    ),
                  ),

                  // Other settings...
                ],
              ),
            ),

            // Other settings cards...
          ],
        ),
      ),
    );
  }
}
