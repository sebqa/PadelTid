import 'package:flutter/material.dart';

class WindSpeedIndicator extends StatelessWidget {
  final double windSpeed;

  WindSpeedIndicator({required this.windSpeed});

  String _getWindDescription(double speed) {
    if (speed >= 32.6) return 'Orkan';
    if (speed >= 28.5) return 'Stærk storm';
    if (speed >= 24.5) return 'Storm';
    if (speed >= 20.8) return 'Stormende kuling';
    if (speed >= 17.2) return 'Hård kuling';
    if (speed >= 13.9) return 'Kuling';
    if (speed >= 10.8) return 'Hård vind';
    if (speed >= 8.0) return 'Frisk vind';
    if (speed >= 5.5) return 'Jævn vind';
    if (speed >= 3.4) return 'Let vind';
    if (speed >= 1.6) return 'Svag vind';
    if (speed >= 0.3) return 'Næsten stille';
    return 'Stille';
  }

  Color _getWindColor(double speed) {
    if (speed >= 24.5) return Colors.red;
    if (speed >= 17.2) return Colors.orange;
    if (speed >= 10.8) return Colors.yellow;
    if (speed >= 5.5) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final description = _getWindDescription(windSpeed);
    final color = _getWindColor(windSpeed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air, size: 24, color: color),
            SizedBox(width: 8),
            Text(
              '$windSpeed m/s',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color),
            ),
            SizedBox(width: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (windSpeed / 32.6).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
