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
                _buildWelcomePage(context),
                _buildLocationSelectorPage(context),
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

  Widget _buildWelcomePage(BuildContext context) {
    return _buildOnboardingPage(
      context,
      'Welcome to PADELTID',
      'Find your perfect padel court with ease',
      Icons.sports_tennis,
    );
  }

  Widget _buildLocationSelectorPage(BuildContext context) {
    return Column(
      children: [
        _buildOnboardingPage(
          context,
          'Select your location',
          'Choose the locations where you want to find padel courts',
          Icons.location_pin,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LocationSelector(
            onLocationsChanged: (locations) {
              setState(() {
                _selectedLocations = locations;
              });
            },
            initialLocations: _selectedLocations,
          ),
        ),
      ],
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
          SizedBox(height: 16),
          Text(
            'Precipitation Probability: ${_precipitationProbabilityThreshold.round()}%',
            style: TextStyle(color: Colors.white),
          ),
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
        ],
      ),
    );
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
    widget.onDismiss(_selectedLocations, _windSpeedThreshold,
        _precipitationProbabilityThreshold, _showUnavailableCourts);
  }

  // Create a new method for the button row
  Widget _buildButtonRow() {
    return Column(
      children: [
        // Circles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
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
        SizedBox(height: 20), // Add space between circles and buttons
        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              TextButton(
                onPressed: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                child: Text('Previous'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              // Dismiss button
              TextButton(
                onPressed: () => _dismissOnboarding(),
                child: Text('Dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              // Next/Get Started button
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < 4) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _dismissOnboarding();
                  }
                },
                child: Text(_currentPage < 4 ? 'Next' : 'Get Started'),
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
          ),
        ),
      ],
    );
  }
}
