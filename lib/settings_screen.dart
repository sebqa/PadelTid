class SettingsScreen extends StatefulWidget {
  final double windSpeedThreshold;
  final double precipitationProbabilityThreshold;
  final bool showUnavailableSlots;
  final Function(double, double, bool) onSettingsChanged;

  SettingsScreen({
    required this.windSpeedThreshold,
    required this.precipitationProbabilityThreshold,
    required this.showUnavailableSlots,
    required this.onSettingsChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late double _windSpeed;
  late double _precipitation;
  late bool _showUnavailable;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _windSpeed = widget.windSpeedThreshold;
    _precipitation = widget.precipitationProbabilityThreshold;
    _showUnavailable = widget.showUnavailableSlots;

    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              _buildSlider(
                'Wind Speed',
                '${_windSpeed.round()} m/s',
                Icons.air,
                _windSpeed,
                (value) {
                  setState(() => _windSpeed = value);
                  widget.onSettingsChanged(_windSpeed, _precipitation, _showUnavailable);
                },
                0,
                20,
              ),
              SizedBox(height: 24),
              _buildSlider(
                'Precipitation Probability',
                '${_precipitation.round()}%',
                Icons.umbrella,
                _precipitation,
                (value) {
                  setState(() => _precipitation = value);
                  widget.onSettingsChanged(_windSpeed, _precipitation, _showUnavailable);
                },
                0,
                100,
              ),
              SizedBox(height: 32),
              _buildSwitch(
                'Show Unavailable Courts',
                _showUnavailable,
                (value) {
                  setState(() => _showUnavailable = value);
                  widget.onSettingsChanged(_windSpeed, _precipitation, _showUnavailable);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, String value, IconData icon, double current,
      Function(double) onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(label, style: TextStyle(color: Colors.white)),
              ],
            ),
            Text(value, style: TextStyle(color: Colors.grey)),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.grey[800],
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey[800],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 