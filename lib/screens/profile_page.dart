import '../widgets/language_selector.dart';
import '../widgets/language_selection_buttons.dart';

Card(
  child: Column(
    children: [
      ListTile(
        leading: const Icon(Icons.person),
        title: Text(localizations.translate('profile')),
        // Other profile details
      ),
      const Divider(),
      // Add the language selector
      const LanguageSelector(), 
      // OR const LanguageSelectionButtons(),
    ],
  ),
), 