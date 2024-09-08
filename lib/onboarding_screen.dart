import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_selector.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(List<String>, double, double, bool) onDismiss;

  const OnboardingScreen({Key? key, required this.onDismiss}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<String> _selectedLocations = [];
  double _windSpeedThreshold = 10.0;
  double _precipitationProbabilityThreshold = 50.0;
  bool _showUnavailableCourts = true;
  String _courtPreference = 'both';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomeAndLocationPage(context),
                _buildWeatherFilterPage(context),
                _buildPreferencesPage(context),
                _buildFinalPage(context),
              ],
            ),
          ),
          // Add this SizedBox to push the buttons up
          SizedBox(height: 20),
          // Move the button row here
          _buildButtonRow(),
          // Add another SizedBox to create space at the bottom
          SizedBox(height: 180),
        ],
      ),
    );
  }

  Widget _buildWelcomeAndLocationPage(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to PADELTID',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                'Select your locations',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              LocationSelector(
                onLocationsChanged: (locations) {
                  setState(() {
                    _selectedLocations = locations;
                  });
                },
                initialLocations: _selectedLocations,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherFilterPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Set Weather Preferences',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Adjust the sliders to set your weather preferences',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Text(
            'Wind Speed: ${_windSpeedThreshold.round()} m/s',
            style: TextStyle(color: Colors.white),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Slider(
                value: _windSpeedThreshold,
                min: 0,
                max: 20,
                divisions: 20,
                label: _windSpeedThreshold.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _windSpeedThreshold = value;
                  });
                },
              ),
              Positioned(
                left: _calculateIndicatorPosition(context, 4, 0, 20),
                child: _buildRecommendedIndicator('4 m/s'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Precipitation Probability: ${_precipitationProbabilityThreshold.round()}%',
            style: TextStyle(color: Colors.white),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Slider(
                value: _precipitationProbabilityThreshold,
                min: 0,
                max: 100,
                divisions: 20,
                label: _precipitationProbabilityThreshold.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _precipitationProbabilityThreshold = value;
                  });
                },
              ),
              Positioned(
                left: _calculateIndicatorPosition(context, 10, 0, 100),
                child: _buildRecommendedIndicator('10%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateIndicatorPosition(
      BuildContext context, double value, double min, double max) {
    final sliderWidth =
        MediaQuery.of(context).size.width - 32; // Adjust for padding
    final fraction = (value - min) / (max - min);
    return 16 +
        (sliderWidth * fraction) -
        8; // 16 for left padding, -8 to center the indicator
  }

  Widget _buildFinalPage(BuildContext context) {
    return _buildOnboardingPage(
      context,
      'You\'re All Set!',
      'Start finding your perfect padel courts now',
      Icons.check_circle,
    );
  }

  Widget _buildOnboardingPage(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.white),
          SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Preferences',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Text(
            'Court Type Preference',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'indoor', label: Text('Indoor')),
              ButtonSegment(value: 'outdoor', label: Text('Outdoor')),
              ButtonSegment(value: 'both', label: Text('Both')),
            ],
            selected: {_courtPreference},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _courtPreference = newSelection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Colors.white;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return Theme.of(context).colorScheme.primary;
                },
              ),
            ),
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Show unavailable courts',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Switch(
                value: _showUnavailableCourts,
                activeColor: Colors.white,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _showUnavailableCourts = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 32),
          Text(
            'You can choose to get notified when conditions change for a timeslot',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setStringList('selected_locations', _selectedLocations);
    await prefs.setDouble('wind_speed_threshold', _windSpeedThreshold);
    await prefs.setDouble('precipitation_probability_threshold',
        _precipitationProbabilityThreshold);
    await prefs.setBool('show_unavailable_courts', _showUnavailableCourts);
    await prefs.setString(
        'court_preference', _courtPreference); // Add this line
    widget.onDismiss(_selectedLocations, _windSpeedThreshold,
        _precipitationProbabilityThreshold, _showUnavailableCourts);
  }

  // Create a new method for the button row
  Widget _buildButtonRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4, // Update this to 4 since we now have 4 pages
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        // Dismiss button
        TextButton(
          onPressed: () => _dismissOnboarding(),
          child: Text('Dismiss'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
        // Get Started button (only on the last page)
        if (_currentPage == 3)
          ElevatedButton(
            onPressed: _dismissOnboarding,
            child: Text('Get Started'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Color(0xFF1E88E5),
              backgroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 16),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
      ],
    );
  }
}

Widget _buildRecommendedIndicator(String label) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      Icon(
        Icons.arrow_drop_up,
        color: Colors.white,
        size: 20,
      ),
    ],
  );
}
