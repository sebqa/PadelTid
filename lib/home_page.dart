import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/consent_snackbar.dart';
import 'package:flutter_application_1/document_service.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'custom_app_bar.dart';
import 'document_widget.dart';
import 'main_list_view.dart';
import 'recommended_lv_holder.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double windSpeedThreshold = 50.0;
  double precipitationProbabilityThreshold = 100.0;
  bool showUnavailableSlots = true;
  late SharedPreferences sharedPreferences;
  late Future<List<Document>> futureDocuments;
  late Future<List<Document>>? recommendedDocuments;
  final DocumentService documentService = DocumentService();
  bool consentShown = false;

  @override
  void initState() {
    super.initState();
    //call showConsentSnackbar from consent_snackbar.dart
    recommendedDocuments = documentService.fetchDocuments(4.0, 10.0, false, true);
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      windSpeedThreshold = sharedPreferences.getDouble('windSpeedThreshold') ?? 50.0;
      precipitationProbabilityThreshold = sharedPreferences.getDouble('precipitationProbabilityThreshold') ?? 100.0;
      showUnavailableSlots = sharedPreferences.getBool('showUnavailableSlots') ?? true;
    });
    _fetchDocuments();
  }

  void _fetchDocuments() {
    futureDocuments = documentService.fetchDocuments(
      windSpeedThreshold,
      precipitationProbabilityThreshold,
      showUnavailableSlots,
      false
    );
    
  }

  Future<void> updateThresholds() async {
    try {
      if( sharedPreferences.getString("user_consent") == "all"){
      await sharedPreferences.setDouble('windSpeedThreshold', windSpeedThreshold);
      await sharedPreferences.setDouble('precipitationProbabilityThreshold', precipitationProbabilityThreshold);
      await sharedPreferences.setBool('showUnavailableSlots', showUnavailableSlots);
      }
      _fetchDocuments();
      setState(() {});
    } catch (e) {
      print('Failed to update thresholds: $e');
    }
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildSettingsDialog(),
    );
  }

  Widget _buildSettingsDialog() {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Adjust Thresholds'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              _buildSlider('Wind Speed', windSpeedThreshold, 0, 50, (value) {
                setState(() => windSpeedThreshold = value);
              }),
              _buildSlider('Precipitation Probability', precipitationProbabilityThreshold, 0, 100, (value) {
                setState(() => precipitationProbabilityThreshold = value);
              }),
              _buildCheckbox('Show unavailable timeslots', showUnavailableSlots, (value) {
                setState(() => showUnavailableSlots = value ?? false);
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Apply'),
            onPressed: () {
              updateThresholds();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text('$label: ${value.round()}${label == 'Wind Speed' ? ' m/s' : '%'}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max.toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  scrollBehavior: MyCustomScrollBehavior(),
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    FirebaseUILocalizations.delegate,
  ],
  supportedLocales: const [Locale('en', 'US')],
  title: 'PADELTID',
  theme: _buildTheme(context),
  home: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 750), // Set your desired max width here
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.tune),
          onPressed: showSettingsDialog,
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF87CEEB), // Sky blue
                    Color(0xFFE0F7FA), // Light blue
                  ],
                ),
              ),
            ),
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const CustomAppBar(),
                SliverRecommendedLV(recommendedDocuments: recommendedDocuments),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildFutureBuilder(),
                    childCount: 1,
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    ),
  ),
);
  }

  Widget _buildFutureBuilder() {
    return FutureBuilder<List<Document>>(
      future: futureDocuments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final groupedDocuments = _groupDocuments(snapshot.data!);
          if(!consentShown){
            showConsentSnackbar(context, onlyShowIfNotSet: true);
            consentShown = true;
          }

          return MainListView(groupedDocuments: groupedDocuments);
        } else {
          return const Center(child: Text('No data'));
        }
      },
    );
  }

  Map<String, List<Document>> _groupDocuments(List<Document> documents) {
    final groupedDocuments = <String, List<Document>>{};
    for (var document in documents) {
      groupedDocuments.putIfAbsent(document.date, () => []).add(document);
    }
    return groupedDocuments;
  }

  ThemeData _buildTheme(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFFF7F07),
      primaryContainer: Colors.white,
      onPrimary: Colors.white,
      secondary: const Color(0xFFBBBBBB),
      onSecondary: const Color(0xFFEAEAEA),
      tertiary: const Color(0xFFFF7F07),
      error: const Color(0xFFF32424),
      onError: Colors.white,
      background: Colors.white,
      onBackground: const Color(0xFF505050),
      surface: Colors.white,
      onSurface: Colors.black,
    );

    return ThemeData.light().copyWith(
      colorScheme: colorScheme,
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.tertiary,
        inactiveTrackColor: colorScheme.onPrimary,
        thumbColor: colorScheme.tertiary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
        overlayColor: colorScheme.onPrimary,
      ),
      textTheme: TextTheme(
        bodySmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SliverRecommendedLV extends StatelessWidget {
  const SliverRecommendedLV({Key? key, required this.recommendedDocuments}) : super(key: key);

  final Future<List<Document>>? recommendedDocuments;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Document>>(
        future: recommendedDocuments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(color: Colors.transparent),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return recommended_lv_holder(documents: snapshot.data!);
          }
        },
      ),
    );
  }
}

class ListViewbuilder extends StatelessWidget {
  const ListViewbuilder({Key? key, required this.documentsForDate}) : super(key: key);

  final List<Document> documentsForDate;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(thickness: 0.5),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentsForDate.length,
      itemBuilder: (_, index) => DocumentWidget(document: documentsForDate[index]),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
  
}
