import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter_application_1/model/location.dart';
import 'package:flutter/rendering.dart';

  final List<Location> _list = [
    Location(name: 'Holbæk Padel Klub', latitude: 52.370216, longitude: 12.739917),
    Location(name: 'Racket Club Roskilde', latitude: 52.370216, longitude: 12.739917),
    Location(name: 'Mørkøv Padel Klub', latitude: 52.370216, longitude: 12.739917),
  ];


Future<List<Location>> _getFakeRequestData(String query) async {
  return await Future.delayed(const Duration(seconds: 1), () {
    return _list.where((e) {
      return e.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  });
}


class MultiSelectSearchRequestDropdown extends StatelessWidget {
  const MultiSelectSearchRequestDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CloudClipper(),
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(300, 70),
              painter: CloudPainter(),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                child: SizedBox(
                  width: 350,
                  height: 50,
                  child: CustomDropdown<Location>.multiSelectSearchRequest(
                    initialItems: [_list[0]],
                    futureRequest: _getFakeRequestData,
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Row(
                        children: [
                          Checkbox(value: isSelected, onChanged: null),
                          Text(
                            item.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      );
                    },
                    onListChanged: (value) {
                      //do something with the value
                      print('MultiSelectSearchRequestDropdown onListChanged value: $value');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base cloud shape
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.02, size.height * 0.4, size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.2, size.width * 0.3, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.05, size.width * 0.55, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.05, size.width * 0.8, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.25, size.width * 0.9, size.height * 0.4)
      ..quadraticBezierTo(size.width, size.height * 0.55, size.width * 0.9, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width * 0.6, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.85, size.width * 0.4, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.85, size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.02, size.height * 0.6, size.width * 0.1, size.height * 0.5)
      ..close();

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path.shift(Offset(0, 4)), shadowPaint);

    // Base color
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, basePaint);

    // 3D effect layers
    final layerPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= 3; i++) {
      final layerPath = path.shift(Offset(-i * 2.0, -i * 2.0));
      canvas.drawPath(layerPath, layerPaint);
    }

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CloudClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.02, size.height * 0.4, size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.2, size.width * 0.3, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.05, size.width * 0.55, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.05, size.width * 0.8, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.25, size.width * 0.9, size.height * 0.4)
      ..quadraticBezierTo(size.width, size.height * 0.55, size.width * 0.9, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width * 0.6, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.85, size.width * 0.4, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.85, size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.02, size.height * 0.6, size.width * 0.1, size.height * 0.5)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}