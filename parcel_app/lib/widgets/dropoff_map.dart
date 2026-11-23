import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Stylised street map with numbered drop-off pins and the user's position.
class DropOffMap extends StatelessWidget {
  const DropOffMap({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            const h = 150.0;
            Widget pin(int n, double x, double y) => Positioned(
                  left: x * w - 11,
                  top: y * h - 11,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text('$n',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                );
            return Stack(
              children: [
                const Positioned.fill(
                    child: CustomPaint(painter: _MapPainter())),
                pin(1, 0.32, 0.42),
                pin(2, 0.74, 0.18),
                pin(3, 0.93, 0.62),
                Positioned(
                  left: 0.55 * w - 14,
                  top: 0.6 * h - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 12, color: AppColors.orange),
                        SizedBox(width: 4),
                        Text('2 open near you',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEDEDF0));

    // Park and water.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.68, w * 0.3, h * 0.4), const Radius.circular(10)),
      Paint()..color = const Color(0xFFCDE8C4),
    );
    final water = Path()
      ..moveTo(w * 0.84, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.45)
      ..quadraticBezierTo(w * 0.9, h * 0.25, w * 0.84, 0);
    canvas.drawPath(water, Paint()..color = const Color(0xFFC6DDF2));

    // Streets grid.
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    for (final x in [0.16, 0.45, 0.66, 0.86]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), street);
    }
    for (final y in [0.3, 0.55, 0.85]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), street);
    }
    final thin = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    for (final x in [0.06, 0.3, 0.56, 0.76]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), thin);
    }

    // Main road.
    final main = Paint()
      ..color = const Color(0xFFF7D78A)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.9), Offset(w, h * 0.5), main);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
